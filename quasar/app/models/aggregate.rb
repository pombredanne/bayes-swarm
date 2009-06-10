class Aggregate
  
  @@entities = [ 'count', 'bodycount', 'titlecount' , 'keywordcount' , 'anchorcount', 'headingcount' ]
  @@lowest_date = Date.civil(2007, 1, 1)
  
  # TODO: should limit the number of intwords
  def self.pie(sdb, from_date, to_date, intwords, entity='count')
    validate_entity(entity)
    low_date, high_date = validate_dates(from_date, to_date)

    intword_name_map = {}
    intwords.each { |iw| intword_name_map[iw.id] = iw.name }

    domains = ((low_date.year)..(high_date.year)).map { |y| "Words#{y}"}
    conditions = { 
      :scantime => low_date.strftime('%Y-%m-%d')..high_date.strftime('%Y-%m-%d'), 
      :id => ([] << intwords).flatten.map { |iw| iw.id } }
    points = {}
    sdb.select(domains, [ "id", "#{entity}"], conditions) do |item|
      p = points[item['id'].first]
      unless p
        p = AggregatePoint.new
        p.intword_id = item['id'].first
        p.count = 0
        points[item['id'].first] = p
      end
      p.count += item[entity].first.to_i
    end
    return points.values.map { |p| [ intword_name_map[p.intword_id.to_i], p.count]}
  end  
  
  def self.validate_entity(entity)
    unless @@entities.include?(entity)
      raise ArgumentError.new("Invalid entity #{entity}") 
    end
  end
    
  def self.validate_dates(from_date, to_date)
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

class AggregatePoint
  attr_accessor :intword_id, :count
end