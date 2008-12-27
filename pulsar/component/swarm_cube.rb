# = Bayes : Swarm-Cube
# Cube is the third component in the bayes-swarm execution chain. 
# It creates denormalized aggregations on the MySql database, in order to speed
# up data access for given queries, such as word aggregations on the entire
# time scale stored in the database.
#
# To be executed it requires access to the database, obviously.
# For example:
#   ruby runner.rb -c swarm_shoal_options.yml \
#                  -f component/swarm_cube
#
# You can use these additional options:
#   --dryRun option for a dryRun that does not affect the database. 
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'util/log'
require 'util/ar'

include Pulsar::Log
include Pulsar::AR

def get_aggregate_stmt(label, interval=nil)
  sql = ""
  sql << "insert into aggregate ( "
  sql << "intword_id, period, count, bodycount, titlecount, keywordcount, "
  sql << "anchorcount, headingcount) "
  sql << "select intword_id , '#{label}' as period ,"
  sql << "sum(count), sum(bodycount) , sum(titlecount), sum(keywordcount), "
  sql << "sum(anchorcount) , sum(headingcount) "
  sql << "from words "
  unless interval.nil?
    sql << "where "
    sql << "scantime >= DATE_SUB(CURDATE(), INTERVAL #{interval} DAY) "
  end
  sql << "group by "
  sql << "intword_id, period"
  
  return sql
end

def conn_execute(conn, sql)
  unless Pulsar::Runner.dryRun? 
    conn.execute(sql)
  else
    dry_log "Executing #{sql}"
  end
end

# And start working ...
with_connection do |conn|
  begin
    conn_execute(conn, "LOCK TABLES aggregate WRITE, words READ")
    log "Tables locked"
    
    conn_execute(conn, "DELETE FROM aggregate")
    log "Aggregate table has been emptied"
    
    conn_execute(conn, get_aggregate_stmt('7d', 7))
    log "7-day aggregate created"
    
    conn_execute(conn, get_aggregate_stmt('2w', 14))    
    log "14-day aggregate created"
        
    conn_execute(conn, get_aggregate_stmt('1m', 30))
    log "30-day aggregate created"
        
    conn_execute(conn, get_aggregate_stmt('3m', 90))
    log "90-day aggregate created"
        
    conn_execute(conn, get_aggregate_stmt('6m', 180))
    log "180-day aggregate created"    
   
    conn_execute(conn, get_aggregate_stmt('al'))    
    log "all-time aggregate created"
    
    conn_execute(conn, "OPTIMIZE TABLE aggregate")
    log "Table optimized"    
  rescue
    warn_log "Unhandled expection while aggregating : #{$!}"
  ensure
    unless conn.nil?
      conn_execute(conn, "UNLOCK TABLES")
      log "Tables unlocked"
    end
  end
end