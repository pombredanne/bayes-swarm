class Intword < ActiveRecord::Base
  belongs_to :language
  has_many :words
  attr_accessor :corr

  validates_presence_of :name, :language_id
  validates_uniqueness_of :name, :scope => :language_id

  def self.find_popular(l_id, interval='1m', n=999999, order_column="imp", visible=1, like=nil)
    first_date = Date.today.subtract_interval(interval)
    condi = "scantime>='#{first_date}' AND language_id = #{l_id}"
    if (!visible.nil?)
      condi = [condi, "visible=#{visible}"].join(' AND ')
    end     
    if (!like.nil?)
      condi = [condi, "name like '#{like}%'"].join(' AND ')
    end
    find(:all,
         :conditions => condi,
         :select => "intwords.id, name, visible, language_id, power(avg(count)*count(*),0.25) as #{order_column}",
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
  def get_time_series(interval, force_complete=false, page_id=nil)
    # interval = '3m', '1m', '1w', etc
    # force_complete = boolean, forces the time series to be completed
    #   ie: very_first_date ... nil ... first_date ... values/zeros .. last_date
    #   intestead of: first_date ... values/zeros .. last_date
    # page_id = count only pages which belong to this id or id array
    very_first_date = Date.today().subtract_interval(interval)
    condi = "scantime>='#{very_first_date}'"
    if (!page_id.nil?)
      if (page_id.class == Array)
        condi = [condi, "page_id IN #{page_id}"].join(' AND ')
      elsif
        condi = [condi, "page_id = #{page_id}"].join(' AND ')
      end
    end
    ws = words.sum(:count, 
                   :conditions=> condi,
                   :order => "date(scantime)",
                   :group=>"date(scantime)")

    fail "Stem has no words" if (ws.size == 0)
    IntwordTimeSeries.new(ws, interval, force_complete)
  end
  
  #def corr(interval, other)
  #  @iwts = self.get_time_series(interval) unless @iwts
  #  other_iwts = other.get_time_series(interval)
  #  if @iwts.complete
  #    puts "#{self.id}, #{self.name}, #{@iwts.values.length} - #{other.id}, #{other.name}, #{other_iwts.values.length}"
  #    return @iwts.correlation(other_iwts)
  #  else
  #    return -10
  #  end    
  #end

  #def <=>(other)
  #  self.corr <=> other.corr
  #end

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
                                     and visible=1
                               group by intword_id 
                               having count(intword_id)>=#{n_hits*2/3.0}")

    iws.each do |iw|
        iwts = iw.get_time_series(interval, true)
        if iwts.complete
          iw.corr = self_iwts.correlation(iwts)
        else
          iw.corr = nil
        end
    end
    
    if (iws == [])
      return nil
    else
      # sort by correlation ascending
      res = iws.select {|iw| !iw.corr.nil?}
      res = res.sort_by {|iw| iw.corr}
      res = res.slice!(-3, res.length)
      return res.reverse
    end
  end


  # computes the correlation matrix on the n most popular intwords
  # for a given language
  def self.find_correlation_matrix(language_id, interval, n)
    popiws = find_popular(language_id, interval, n)
    corr_popiws = []
    
    popiws.each_with_index do |iw_a, i_a|
      corr_popiws[i_a] = []
      iwts_a = iw_a.get_time_series(interval)
      popiws.each_with_index do |iw_b, i_b|
        corr_popiws[i_a][i_b] = iwts_a.correlation(iw_b.get_time_series(interval))
      end
    end
    return popiws, corr_popiws
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
  
  def initialize(words, interval, force_complete=false)
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
    
    # very_first_date ... nil ... first_date ... values/zeros .. last_date
    # loop on missing dates and fill with zeros
    ((first_date..last_date).to_a - dates).each do |d|
      pos = d - first_date
      values.insert(pos, 0)
      dates.insert(pos, d)
    end
    
    if force_complete
      # loop on very_first_date ... first_date and fill with nil
      (first_date - 1).downto(very_first_date) do |d|
        values.insert(0, nil)
        dates.insert(0, d)
      end
    end
  
    @dates = dates
    @values = values
  end

  def correlation(other)
    self.values.correlation(other.values)
  end
end
