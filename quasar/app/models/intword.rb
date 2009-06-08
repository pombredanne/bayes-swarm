class Intword < ActiveRecord::Base
  belongs_to :language
    
  @@entities = [ 'count', 'bodycount', 'titlecount' , 'keywordcount' , 'anchorcount', 'headingcount' ]
  @@lowest_date = Date.civil(2007, 1, 1)
  
  # TODO: should limit the number of intwords  
  def time_series(sdb, interval, entity='count', page_id=nil)
    validate_entity(entity)
    
    # TODO: should validate date like other entities    
    low_date = Date.from_interval(interval)
    low_date = @@lowest_date if low_date < @@lowest_date
    high_date = Date.today()
    domains = ((low_date.year)..(high_date.year)).map { |y| "Words#{y}"}
    conditions = { 
      :scantime => low_date.strftime('%Y-%m-%d')..high_date.strftime('%Y-%m-%d'),
      :id => id }
    conditions[:page_id] = page_id if page_id

    points = {}
    sdb.select(domains, ["#{entity}", "scantime"], conditions) do |item|
      p = points[item['scantime'].first]
      unless p
        p = TimeSeriePoint.new
        p.scantime = Date.strptime(item["scantime"].first, '%Y-%m-%d')
        p.count = 0
        points[item['scantime'].first] = p
      end
      p.count += item[entity].first.to_i
    end
    return points.values.sort_by { |p| p.scantime }.map { |p| [ p.scantime, p.count]}
  end
  
  protected
  def validate_entity(entity)
    unless @@entities.include?(entity)
      raise ArgumentError.new("Invalid entity #{entity}") 
    end
  end  
end

class TimeSeriePoint
  attr_accessor :scantime, :count
end