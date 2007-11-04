class Intword < ActiveRecord::Base
  belongs_to :language
  has_many :words
  has_many :intword_time_series
  has_one :intword_statistic

  def self.find_popular(l_id, n=999999, order_column="imp")
    find(:all, 
         :include => :intword_statistic, 
         :conditions => "language_id = #{l_id} AND imp > 0",
         :limit => n,
         :order => "#{order_column} DESC")
  end
  
  # returns last 3 month values
  # lastdate is today, firstdate is the oldest date (in the 3m scope)
  # if some days are missing (stem not seen in pages) we fill with zeros
  def get_3m_time_series
    tseries = intword_time_series.find(:all, :conditions=>"date>='#{Date.today()<<3}'", :order=>"date")
    
    values = Array.new()
    dates = Array.new()
    last_date = Date.today()
    first_date = tseries[0].date
    
    first_date.upto(last_date) do |d|
      dates << d
      values << 0
    end
    
    tseries.each do |ts|
      pos = ts.date - first_date
      values[pos] = ts.count
    end
    
    Intword3mTimeSeries.new(dates, values)
  end
end


class IntwordTimeSeries < ActiveRecord::Base
  belongs_to :intword
end

class IntwordStatistic < ActiveRecord::Base
  belongs_to :intword
end

class Intword3mTimeSeries
  attr_accessor :dates, :values

  def initialize(dates, values)
    @dates = dates
    @values = values
  end

  # returns a n=>date hash to be used with Gruff.labels()
  # only montly dates are returned
  def labels
    l = Hash.new()
#    dates.each_with_index do |d, i|
#      l[i] = d
#    end
    3.downto(0) do |i|
      cur_date = dates.last<<i
      if ((cur_date - dates.first).to_i >= 0)
        l[(cur_date - dates.first).to_i] = cur_date.strftime("%b %d")
      end
    end
    l
  end
end

# Intword.find(1).intword_statistic
# => #<IntwordStatistic:0xb65f6764 @attributes={"imp"=>"35.23989996", "intword_id"=>"1", "avg_count"=>"0.39155444", "n_hits"=>"90"}>

# l_id = 2
# iws = Intword.find(:all, :include => :intword_statistic, :conditions => "language_id = #{l_id}", :limit => 10, :order => "imp DESC")
