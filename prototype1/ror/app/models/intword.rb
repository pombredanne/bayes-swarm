class Intword < ActiveRecord::Base
  belongs_to :language
  has_many :words

  validates_presence_of :name, :language_id
  validates_uniqueness_of :name, :scope => :language_id

  def self.find_popular(l_id, n_months=1, n=999999, order_column="imp", visible=1)
    find(:all,
         :conditions => "scantime>='#{Date.today()<<n_months}' AND language_id = #{l_id} AND visible=#{visible}",
         :select => "intwords.id, name, sqrt(avg(count)*count(*)) as #{order_column}",
         :joins => "LEFT JOIN words on words.intword_id = intwords.id",
         :group => "intwords.id, name",
         :order => "#{order_column} desc",
         :limit => n)
  end

#  def after_initialize
#  end

  # returns the first date ever this intword was found
  def oldest_scandate()
    # do not fetch db every time, check if we already fetched it
    if (@oldest_scandate)
      @oldest_scandate
    else
      if (result = words.find(:first, :order=>"scantime"))
        @oldest_scandate = result.scantime.to_date
      else
        # FIXME: protect oldest_scandate with something like ever_seen?
        @oldest_scandate = Date.today + 10000
      end    
    end
  end
 
  # returns last n_month values
  # lastdate is today, firstdate is the oldest date (in the n_months scope)
  # if some days are missing (stem not seen in pages) we fill with zeros
  def get_time_series(interval)
    # FIXME: add page_id parameter like so [ "category IN (?)", categories]
    # FIXME: add /n_pages to avg_count (based on the language of the stem)
    very_first_date = Date.today().subtract_interval(interval)
    ws = words.sum(:count, 
                   :conditions=>"scantime>='#{very_first_date}'",
                   :order => "date(scantime)",
                   :group=>"date(scantime)")

    fail "Stem has no words" if (ws.size == 0)
    IntwordTimeSeries.new(ws, interval)
  end
  
  def find_most_correlated(interval)
    begin
      self_iwts = self.get_time_series(interval)
    rescue RuntimeError
      return nil
    end
    
    # correlations are shown only for stems which are old enough
    # (ie the ones which have a complete time series)
    return nil if !self_iwts.complete 

    last_date = Date.today()
    first_date = last_date.subtract_interval(interval)
    n_hits = last_date - first_date
    # find only intwords which have at least 2/3 of the words in the chosen period
    iws = Intword.find_by_sql("select intword_id as id, name, language_id
                               from (select intword_id, date(scantime) 
                                     from words where scantime>'#{first_date}' 
                                     group by intword_id, date(scantime)) a, 
                                    intwords iw 
                               where a.intword_id=iw.id 
                                     and iw.language_id=#{self.language_id} 
                                     and id not in (#{self.id})
                               group by intword_id 
                               having count(intword_id)>=#{n_hits*2/3.0}")

    iwtses = Array.new()
    iws2 = Array.new()
    iws.each_with_index do |iw, i|
      begin
        iwtses << iw.get_time_series(interval)
        iws2 << iw
      rescue RuntimeError
        # current stem has no words, skipping
        nil
      end
    end
    iws = iws2

    # FIXME: this armonizes to the oldest one in the array, add a new parameter to armonize so that
    # it can be armonized to a specified one (ie the independent variable).
    # Useless if previous FIXME gets fixed
    armonized_iwtses = IntwordTimeSeries.armonize(iwtses)
    corr_iwtses = ActiveSupport::OrderedHash.new()
 
    iws.each_with_index do |iw, i|
      begin
        corr_iwtses[iw] = self_iwts.correlation(armonized_iwtses[i])
      rescue RuntimeError
        # stem has not enough data for calculating correlation, skipping
        nil
      end
    end

    if (corr_iwtses == [])
      return nil
    else
      # sort by correlation ascending
      res = corr_iwtses.sort {|x,y| x[1] <=> y[1]}
      # keep only 3 records
      res2 = ActiveSupport::OrderedHash.new()
      2.downto(0) do
        e = res.pop
        res2[e[0]] = e[1]
      end
    
      return res2
    end
  end

end

class IntwordTimeSeries
  attr_accessor :dates, :values

  # here we save the interval on which the time series is extracted
  def interval
    @interval
  end

  # this attribute shows if the first date is actually Today - interval
  # or not, so that we know if the stem is old enough for plotting
  # correlations or not
  def complete
    @complete
  end
  
  def initialize(words, interval)
    @interval = interval
    last_date = Date.today()
    very_first_date = last_date.subtract_interval(interval)
    
    values = words.values
    dates = words.keys.map {|x| Date.strptime(x, '%Y-%m-%d')}

    first_date = dates[0]
    # check if ts si complete
    if (first_date == very_first_date)
      @complete = true
    else
      @complete = false
    end
    
    if (values.size != last_date - very_first_date+1)
      # loop on missing dates and fill with zeros
      ((first_date..last_date).to_a - dates).each do |d|
        pos = d - first_date
        values.insert(pos, 0)
        dates.insert(pos, d)
      end
    end
  
    @dates = dates
    @values = values
  end

  # returns a n=>date hash to be used with Gruff.labels()
  # only monthly dates are returned
  def labels
    l = Hash.new()
    i = 0
    cur_date = dates.last<<i
    while ((cur_date - dates.first).to_i >= 0)
      l[(cur_date - dates.first).to_i] = cur_date.strftime("%b %d")
      i += 1
      cur_date = dates.last<<i
    end
    l
  end
  
  # shifts dates and values arrays and returns a new IntwordTimeSeries
  def shift(n)
    n.times {
      self.dates.insert(0, 0)
      self.values.insert(0, 0)
    }
    self
  end
  
  # given an array of IntwordTimeSeries, armonizes each dates series
  # so that they can be plotted together
  def self.armonize(others)
    # find oldest one
    oldest = 0
    oldest_date = Date.today()
    others.each_with_index do |o, i|
      if (o.dates.first < oldest_date)
        oldest = i
        oldest_date = o.dates.first
      end
    end

    res = Array.new()
    # find gap and shift
    others.each do |o|
      gap = others[oldest].dates.length - o.dates.length
      shifted_o = o.shift(gap)
      shifted_o.dates = others[oldest].dates
      res << shifted_o
    end
    res
  end

  def correlation(other)
    self.values.correlation(other.values)
  end
end

