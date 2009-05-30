# = Test : Amazon SimpleDB Test
# A simple component designed to verify that
# the ActiveSdb bindings are working properly and to do a littel benchmark
# to transfer a 1000 items back and forward to Amazon SimpleDb. Run with
#
#   ruby runner.rb -t test/active_sdb -a your_access_key -s your_secret_key
#
# Additional flags:
#   --create: To empty and create a new Test sdb domain and load it with 1000
#       items. If this flag is not provided, the items will be only read from
#       the domain without creating it.
#
# If everything is fine, it should connect to Amazon SimpleDB, optionally load
# 1000 items, read them back and produce some basic performance metrics.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2009 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

require 'right_aws'
require 'sdb/active_sdb'
require 'date'
require 'util/log'

include Pulsar::Log

class Test < RightAws::ActiveSdb::Base
end

access_key = get_opt("-a")

secret_key = get_opt("-s")
if !access_key || !secret_key
  warn_log "You must specify both the AWS access key and AWS secret key"
  exit(1)
end

# connect to SDB
log "Connecting to SDB..."
RightAws::ActiveSdb.establish_connection(access_key, secret_key)
log "Connected."

if flag?("--create")
  # create domain
  log "Refreshing domain..."
  Test.delete_domain
  Test.create_domain
  log "Domain refreshed."

  log "Creating 1000 elements..."
  start = Time.now.to_i
  10.times do |j|
    100.times do |i|
      Test.create 'name' => "test#{j*100+i}" ,  
                  'even' => ((j*100+i) % 2 == 0).to_s, 
                  'when' => (Time.now - rand(365)*24*60*60).strftime('%Y-%m-%d')
    end
    log "Created #{(j+1)*100} items."
  end
  stop = Time.now.to_i
  log "Done. Total save time: #{stop-start}. Per item: #{(stop-start)/1000.0}"
end

log "Retrieving all items, 250 at a time..."
start = Time.now.to_f
fetched_items = []
fetched_items.concat(Test.select(:all, :limit => 250))
begin
   fetched_items.concat(Test.select(:all, 
      :limit => 250, :next_token => Test.next_token))
end while Test.next_token
odd_items = fetched_items.count { |t| t[:even].to_s == 'false'}
stop = Time.now.to_f
log "Done. Total odd items: #{odd_items}"
log "Total fetch time: #{stop-start}. " +
    "Per item (#{fetched_items.size} items): " + 
    "#{(stop-start)/fetched_items.size.to_f}"

log "Fetching first 250 items selecting by date"
start = Time.now.to_f
fetched_items = []
fetched_items.concat(Test.select(:all, :conditions => "when > '2008-06-01'"))
fetched_items.each do |t|
  parsed_date = Date.strptime(t[:when][0], '%Y-%m-%d')
  check_date = Date.civil(2008, 6, 1)
  puts "Retrieved date #{t} which shouldn't be here!" if parsed_date < check_date
end
stop = Time.now.to_f
log "Total query time: #{stop-start}. " +
    "Per item (#{fetched_items.size} items): " +
    "#{(stop-start)/fetched_items.size.to_f}"

