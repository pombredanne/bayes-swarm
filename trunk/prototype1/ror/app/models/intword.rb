class Intword < ActiveRecord::Base
  belongs_to :language
  has_many :words

  def self.find_popular(l_id, n=999999, order_column="imp")
    n_months = 3
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

