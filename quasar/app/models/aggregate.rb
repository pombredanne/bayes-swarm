class Aggregate
  
  @@entities = [ 'count', 'bodycount', 'titlecount' , 'keywordcount' , 'anchorcount', 'headingcount' ]
  @@periods = [ '7d', '2w', '1m', '3m', '6m', '1y' ]
  @@lowest_date = Date.civil(2007, 1, 1)
  
  # TODO: should limit the number of intwords
  def self.pie(sdb, intwords, entity='count', period='1y')
    validate_entity(entity)
    validate_period(period)
    # TODO: should validate date like other entities
    low_date = Date.from_interval(period)
    low_date = @@lowest_date if low_date < @@lowest_date
    high_date = Date.today()    

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
  
  def self.validate_period(period)
    unless @@periods.include?(period)
      raise ArgumentError.new("Invalid period #{period}")
    end
  end
end

class AggregatePoint
  attr_accessor :intword_id, :count
end