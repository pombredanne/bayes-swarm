class Aggregate
  
  @@entities = [ 'count', 'bodycount', 'titlecount' , 'keywordcount' , 'anchorcount', 'headingcount' ]
  @@lowest_date = Date.civil(2007, 1, 1)
  
  def self.motion(sdb, from_date, to_date, intwords, kind=nil, entity='count', pages=nil)
    validate_entity(entity)
    low_date, high_date = validate_dates(from_date, to_date)
    
    page_name_map = {}
    (pages ? Page.find(pages) : Page.find(:all)).each { |page| page_name_map[page.id] = page.source.name }        

    domains = ((low_date.year)..(high_date.year)).map { |y| "Words#{y}"}
    conditions = { 
      :scantime => low_date.strftime('%Y-%m-%d')..high_date.strftime('%Y-%m-%d'), 
      :id => ([] << intwords).flatten.map { |iw| iw.id } }
    conditions[:page_id] = pages if pages      
    conditions[:page_kind] = kind if kind
    points = {}
    sdb.select(domains, [ "name", "id", "page_id", "#{entity}", "scantime"], conditions) do |item|
      key = "#{item['id'].first}_#{item['scantime'].first}"
      p = points[key]
      unless p
        p = MotionPoint.new
        p.id = item['id'].first.to_i
        p.name = item["name"].first
        p.scantime = Date.strptime(item["scantime"].first, '%Y-%m-%d')
        page_name_map.values.each do |source_name|
          p.page_counts[source_name] = 0
        end
        points[key] = p
      end
      page_id = item['page_id'].first.to_i
      source_name = page_name_map[page_id]
      p.page_counts[source_name] += item[entity].first.to_i
    end
    return points.values.map do |p|
      row = [ p.name, p.scantime ]
      # Add the counts for each source iterating by sorted key (source name), to preserve column alignment.
      p.page_counts.keys.sort.each { |key| row << p.page_counts[key] }
      row
    end
  end
  
  def self.pie(sdb, by, from_date, to_date, intwords, kind=nil, entity='count', pages=nil)
    validate_entity(entity)
    low_date, high_date = validate_dates(from_date, to_date)

    key_name_map = {}
    key = nil
    if by == :intword
      key = 'id'
      intwords.each { |iw| key_name_map[iw.id] = iw.name }
    elsif by == :page
      key = 'page_id'
      (pages ? Page.find(pages) : Page.find(:all)).each { |page| key_name_map[page.id] = page.source.name }        
    end

    domains = ((low_date.year)..(high_date.year)).map { |y| "Words#{y}"}
    conditions = { 
      :scantime => low_date.strftime('%Y-%m-%d')..high_date.strftime('%Y-%m-%d'), 
      :id => ([] << intwords).flatten.map { |iw| iw.id } }
    conditions[:page_id] = pages if pages      
    conditions[:page_kind] = kind if kind
    points = {}
    sdb.select(domains, [ key, "#{entity}"], conditions) do |item|
      name = key_name_map[item[key].first.to_i]
      p = points[name]
      unless p
        p = AggregatePoint.new
        p.name = name
        points[name] = p
        p.count = 0        
      end
      p.count += item[entity].first.to_i
    end
    return points.values.map { |p| [ p.name, p.count]}
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
  attr_accessor :name, :count
end

class MotionPoint
  attr_accessor :name, :id, :scantime, :page_counts
  
  def initialize
    @page_counts = {}
  end
end