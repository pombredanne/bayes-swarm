class Intword < ActiveRecord::Base
  belongs_to :language
    
  @@entities = [ 'count', 'bodycount', 'titlecount' , 'keywordcount' , 'anchorcount', 'headingcount' ]
  @@lowest_date = Date.civil(2007, 1, 1)

  def time_series(sdb, from_date, to_date, kind=nil, entity='count', pages=nil)
    validate_entity(entity)
    low_date, high_date = validate_dates(from_date, to_date)
    domains = ((low_date.year)..(high_date.year)).map { |y| "Words#{y}"}
    conditions = { 
      :scantime => low_date.strftime('%Y-%m-%d')..high_date.strftime('%Y-%m-%d'),
      :id => id }
    conditions[:page_id] = pages if pages
    conditions[:page_kind] = kind if kind    

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
  
  def validate_dates(from_date, to_date)
    if from_date
      begin
        from_date = Date.strptime(from_date, '%Y/%m/%d')
        from_date = @@lowest_date if from_date < @@lowest_date
      rescue ArgumentError
        from_date = Date.today << 1  # 1 month ago
      end
    else
      from_date = Date.today << 1  # 1 month ago
    end

    if to_date
      begin
        to_date = Date.strptime(to_date, '%Y/%m/%d')
        to_date = Date.today if to_date < from_date
      rescue ArgumentError
        to_date = Date.today
      end
    else
      to_date = Date.today
    end    
    return from_date, to_date
  end

end

class TimeSeriePoint
  attr_accessor :scantime, :count
end