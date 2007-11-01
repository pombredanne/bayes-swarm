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
end

class IntwordTimeSeries < ActiveRecord::Base
  belongs_to :intword
end

class IntwordStatistic < ActiveRecord::Base
  belongs_to :intword
end

# Intword.find(1).intword_statistic
# => #<IntwordStatistic:0xb65f6764 @attributes={"imp"=>"35.23989996", "intword_id"=>"1", "avg_count"=>"0.39155444", "n_hits"=>"90"}>

# l_id = 2
# iws = Intword.find(:all, :include => :intword_statistic, :conditions => "language_id = #{l_id}", :limit => 10, :order => "imp DESC")
