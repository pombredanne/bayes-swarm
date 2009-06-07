class Sdb
  
  # domains: enumerable
  # entities: enumerable
  # conditions : hash
  def select(domains, entities, conditions, limit=2500)
    start = Time.now
    items = []
    condition_keys = []
    condition_values = []
    conditions.each_pair do |k, v|
      if v.is_a?(Range)
        condition_keys << "#{k} >= ? and #{k} <= ?"
        condition_values << v.to_a.first << v.to_a.last
      elsif v.is_a?(Array)
        condition_keys << "#{k} in (" + Array.new(v.length, "?").join(',') + ')'
        condition_values += v
      else
        condition_keys << "#{k} = ?"
        condition_values << v
      end
    end
    connection = RightAws::SdbInterface.new(
      QuasarConfig[:sdb_access_key], QuasarConfig[:sdb_secret_key],
      {:port => QuasarConfig[:sdb_port], :protocol => QuasarConfig[:sdb_protocol]})
    entities = entities.join(',') 
    domains.each do |domain|
      q = ["select #{entities} from #{domain} where #{condition_keys.join(' and ')} limit #{limit}"]
      q += condition_values
      next_token = nil
      begin
        RAILS_DEFAULT_LOGGER.info q.inspect
        res = connection.select(q, next_token)
        res[:items].each do |item|
          if block_given?
            yield item.values.first
          else
            items << item.values.first
          end
        end
        next_token = res[:next_token]
      end while next_token
    end
    stop = Time.now
    RAILS_DEFAULT_LOGGER.info "SDB Request completed in #{stop.to_f - start.to_f} secs."
    return items
  end
end