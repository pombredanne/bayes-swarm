class Intword < ActiveRecord::Base
  belongs_to :language
  has_many :words
  has_many :intword_time_series
  has_one :intword_statistic

  def self.find_popular(l_id, n=999999, order_column="imp")
    find(:all, 
         :include => :intword_statistic, 
         :conditions => "language_id = #{l_id} AND #{order_column} > 0",
         :limit => n,
         :order => "#{order_column} DESC")
  end
  
  # returns last 3 month values
  # lastdate is today, firstdate is the oldest date (in the 3m scope)
  # if some days are missing (stem not seen in pages) we fill with zeros
  def get_time_series(n_months)
    # FIXME: add page_id parameter like so [ "category IN (?)", categories]
    # FIXME: add /n_pages to avg_count (based on the language of the stem)
    ws = words.find(:all,
                    :select => "date(scantime) as date, avg(count) as count",
                    :conditions => "scantime>='#{Date.today()<<n_months}'",
                    :order => "date(scantime)",
                    :group => "date(scantime)")

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
end

class IntwordStatistic < ActiveRecord::Base
  belongs_to :intword
end

class IntwordTimeSeries
  attr_accessor :dates, :values

  def initialize(dates, values)
    @dates = dates
    @values = values
  end

  # returns a n=>date hash to be used with Gruff.labels()
  # only montly dates are returned
  def labels
    l = Hash.new()
    3.downto(0) do |i|
      cur_date = dates.last<<i
      if ((cur_date - dates.first).to_i >= 0)
        l[(cur_date - dates.first).to_i] = cur_date.strftime("%b %d")
      end
    end
    l
  end
  
  # FIXME: add a "kind of intersection" method to join single time series
  # for multivariate plots
end

# Intword.find(1).intword_statistic
# => #<IntwordStatistic:0xb65f6764 @attributes={"imp"=>"35.23989996", "intword_id"=>"1", "avg_count"=>"0.39155444", "n_hits"=>"90"}>

# l_id = 2
# iws = Intword.find(:all, :include => :intword_statistic, :conditions => "language_id = #{l_id}", :limit => 10, :order => "imp DESC")
