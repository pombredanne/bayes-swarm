class Intword < ActiveRecord::Base
  belongs_to :language
  has_many :words

  validates_presence_of :name, :language_id
  validates_uniqueness_of :name, :scope => :language_id

  def self.find_popular(l_id, n_months=1, n=999999, order_column="imp")
    find(:all,
         :conditions => "scantime>='#{Date.today()<<n_months}' AND language_id = #{l_id}",
         :select => "intwords.id, name, sqrt(avg(count)*count(*)) as #{order_column}",
         :joins => "LEFT JOIN words on words.intword_id = intwords.id",
         :group => "intwords.id, name",
         :order => "#{order_column} desc",
         :limit => n)
  end
  
  # returns last n_month values
  # lastdate is today, firstdate is the oldest date (in the n_months scope)
  # if some days are missing (stem not seen in pages) we fill with zeros
  def get_time_series(n_months)
    # FIXME: add page_id parameter like so [ "category IN (?)", categories]
    # FIXME: add /n_pages to avg_count (based on the language of the stem)
    ws = words.find(:all,
                    :select => "date(scantime) as date, sum(count) as count",
                    :conditions => "scantime>='#{Date.today()<<n_months}'",
                    :order => "date(scantime)",
                    :group => "date(scantime)")
    fail "Stem has no words" if (ws.size == 0)
    
    values = Array.new()
    dates = Array.new()
    last_date = Date.today()
    first_date = Date.strptime(ws.first.date, '%Y-%m-%d')

    first_date.upto(last_date) do |d|      
      dates << d
      values << 0
    end
    
    ws.each do |w|
      pos = Date.strptime(w.date, '%Y-%m-%d') - first_date
      values[pos] = w.count
    end
    
    IntwordTimeSeries.new(dates, values)
  end
  
  def find_most_correlated(period)
    iws = Intword.find(:all,
                       :conditions => ["language_id IN (?) AND id NOT IN (?)", 
                                       self.language_id, self.id])
 
    begin
      self_iwts = self.get_time_series(period)
    rescue RuntimeError
      return nil
    end
 
    iwtses = Array.new()
    iws2 = Array.new()
    # FIXME: there is no point in extracting the full time series if the independent
    # variable has a shorter history, get_time_series should accept a Date
    # parameter so that we can pass the independent variable's first date
    iws.each_with_index do |iw, i|
      begin
        iwtses << iw.get_time_series(period)
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

  def initialize(dates, values)
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
 
    IntwordTimeSeries.new(self.dates,
                          self.values)
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

