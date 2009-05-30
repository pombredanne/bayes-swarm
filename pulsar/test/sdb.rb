# = Test : Amazon SimpleDB Test
# A simple component designed to verify that
# the basic Sdb bindings are working properly and to do a littel benchmark
# to transfer a 1000 items back and forward to Amazon SimpleDb.
#
# This test uses SdbInterface directly, without using an ActiveSdb facade.
# Run with
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
require 'date'
require 'util/log'
require 'util/sdb_batchput'

include Pulsar::Log

access_key = get_opt("-a")

secret_key = get_opt("-s")
if !access_key || !secret_key
  warn_log "You must specify both the AWS access key and AWS secret key"
  exit(1)
end

# connect to SDB
log "Connecting to SDB..."
sdb = RightAws::SdbInterface.new(access_key, secret_key)
log "Connected."

if flag?("--create")
  # create domain
  log "Refreshing domain..."
  sdb.delete_domain "Test"
  sdb.create_domain "Test"
  log "Domain refreshed."

  log "Creating 1000 elements..."
  start = Time.now.to_i
  10.times do |j|
    100.times do |i|
      attributes = { 
          'even' => ((j*100+i) % 2 == 0).to_s, 
          'when' => (Time.now - rand(365)*24*60*60).strftime('%Y-%m-%d')
      }
      sdb.put_attributes("Test", "test#{j*100+i}", attributes)
    end
    log "Created #{(j+1)*100} items."
  end
  stop = Time.now.to_i
  log "Done. Total save time: #{stop-start}. Per item: #{(stop-start)/1000.0}"
end

if flag?("--batchcreate")
  # create domain
  log "Refreshing domain..."
  sdb.delete_domain "Test"
  sdb.create_domain "Test"
  log "Domain refreshed."
  
  log "Creating 1000 elements..."
  start = Time.now.to_f
  40.times do |j|
    items = {}
    25.times do |i|
      attributes = { 
          'even' => ((j*25+i) % 2 == 0).to_s, 
          'when' => (Time.now - rand(365)*24*60*60).strftime('%Y-%m-%d')
      }
      items["test#{j*25+i}"] = attributes
    end
    sdb.batch_put_attributes("Test", items)
    log "Created #{(j+1)*25} items."
  end
  stop = Time.now.to_f
  log "Done. Total save time: #{stop-start}. Per item: #{(stop-start)/1000.0}"
end
  
log "Retrieving all items, 250 at a time..."
start = Time.now.to_f
fetched_items = []
next_token = nil
begin
  res = sdb.select('select even, when from Test limit 250', next_token)
  fetched_items.concat(res[:items])
  next_token = res[:next_token]
end while next_token
odd_items = fetched_items.count { |t| t.values.first["even"].to_s == 'false'}
stop = Time.now.to_f
log "Done. Total odd items: #{odd_items}"
log "Total fetch time: #{stop-start}. " +
    "Per item (#{fetched_items.size} items): " +
    "#{(stop-start)/fetched_items.size.to_f}"

log "Fetching first 250 items selecting by date"
start = Time.now.to_f
res = sdb.select('select even, when from Test where when > "2008-06-01" limit 250')
fetched_items = res[:items]
fetched_items.each do |t|
  parsed_date = Date.strptime(t.values.first["when"][0], '%Y-%m-%d')
  check_date = Date.civil(2008, 6, 1)
  puts "Retrieved date #{t} which shouldn't be here!" if parsed_date < check_date
end
stop = Time.now.to_f
log "Total query time: #{stop-start}. " + 
    "Per item (#{fetched_items.size} items): " +
    "#{(stop-start)/fetched_items.size.to_f}"
