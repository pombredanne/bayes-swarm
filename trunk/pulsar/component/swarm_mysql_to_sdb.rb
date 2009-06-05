# = Bayes : Amazon SimpleDB migrator
# A script to migrate contents from Bayes MySQL structure into Amazon SimpleDB.
#
# Run with
#
#   ruby runner.rb -c swarm_shoal_options.yml \
#       -t component/swarm_mysql_to_sdb -d <scantime> [--delete_domain]
#
# The script reads all the words stored in a Swarm MySQL db for a given date
# and uploads them onto an Amazon SDB instance (http://aws.amazon.com/simpledb/).
#
# You must provide the date in the yyyy-mm-dd format. Read data are stored
# in separate SDB domains per year, prefixed by 'Words'. E.g.: Words2009, Words2008.
#
# You must define your Amazon Access key and Secret key into the configuration
# file (swarm_shoal_options.yml) for this script to work (along with the MySQL
# credentials for the database that contain the data to move).
#
# The script accepts the extra options:
#   --start_intword_id <id> : The intword_id (inclusive) to start importing from.
#                             The importer process intwords sequentially by
#                             increasing id.
#   --delete_domain : deletes the affected SDB domain before importing data.
#                     WARNING WARNING! Populating an SDB domain take a lot of
#                     time and costs money. You must be really sure before including
#                     this option!
#   --dryRun : performs a test run that do not actually send data to SDB.
#
# You might consider migrating data into SDB when scalability or MySQL performances
# start to become an issue, and/or you are looking for a more cost effective
# solution to store word counts and timeseries. Since the Swarm database is
# basically unstructured, it is easy to port to a non-relational storage like 
# SDB.
#
# Using the util/sdb_batchput patch, this script on a normal computer
# (a 2.4Ghz Macbook pro) achieves a throughput of approx. 17 words/second
# (equivalent to ~1K words/min) where 'word' refers to the set of counters for
# a single word, date and page (basically a row in the MySQL Words table).
#
# Multiple instances of this script can be run concurrently to achieve better
# parallelism until the network bandwidth is saturated (either on the trasmitter
# side or by Amazon throttling on the receiver side).
#
# To limit the amount of data to be transferred, the script uses a count
# threshold to decide whether a given word occurrence should be moved into SDB.
# All the words occurrences that appear few times on a page for a given day are
# skipped. See the code for the definition of 'few'.
#
# This importer is fault-tolerant:
# - the underlying right_aws library re-opens and re-negotiates http connections
#   to SDB transparently whenever they fail.
# - the MySQL extraction is restarted at the last checkpoint whenever any
#   unexpected error occurs.
#
# SDB Items are keyed by <intword_id>_<page_id>_<scantime> and each SDB item
# collects the counters for all the MySQL rows matching such key (for example,
# duplicated counters derived from multiple hits on different pages belonging to
# the same RSS feed). If the contents of the underlying MySQL do not change, it
# is therefore safe to re-process the script in case of failure, since the
# inserted items will overwrite the previous ones.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2009 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

require 'date'
require 'iconv'
require 'right_aws'
require 'util/sdb_batchput'
require 'util/log'
require 'util/ar'

require 'bayes/ar'

include Pulsar::Log
include Pulsar::AR      

d = get_opt("-d", Date.today.strftime("%Y-%m-%d"))
scantime = Date.strptime(d, '%Y-%m-%d')

start_intword_id = get_opt("--start_intword_id", "-1").to_i

# How many failures do we accept before giving up?
max_exception_count = 20

# Handle trapping of Ctrl-C signals. They behave like exceptions, but
# we want to treat them differently (no retrying).
interrupted = false
trap("INT") { interrupted = true }

# Defines the counters threshold a candidate SDB item must satisfy to be
# effectively transferred into SDB.
def worthy?(item)
  item['count'] >= 5 || item['headingcount'] >= 1 || 
  item['titlecount'] >= 1 || item['anchorcount'] >= 2
end

# This LATIN1 to UTF8 converter is needed because we have some Latin1
# characters in the intwords which would make the HMAC sdb signature fail
# if not converted. For example, intword 394.
# converter = Iconv.new("UTF8", "LATIN1")

unless Pulsar::Runner.dryRun?
  log "Opening SDB Connection"
  sdb_opts = Pulsar::Runner.opts['sdb']
  sdb = RightAws::SdbInterface.new(sdb_opts[:access_key], sdb_opts[:secret_key])
  if flag?('--delete_domain')
    sdb.delete_domain "Words#{scantime.year}"
    log "Deleted domain Words#{scantime.year}"
  end
  sdb.create_domain "Words#{scantime.year}"
  log "Created domain Words#{scantime.year}"
end

with_connection do |connection| 
  # Cache some data to avoid continuous db lookups
  unsafe_intwords = Intword.get_i18n_unsafe_words_hash
  page_map = {}
  Page.find(:all).each do |p|
    page_map[p.id] = {'url'=> p.url, 'kind'=> p.kind.kind}
  end
  
  # Retry and global counters
  last_stored_intword = start_intword_id
  count = 0
  exception_count = 0
  success = false
  begin
    if exception_count > 0
      log "Retrying... attempt #{exception_count}"
      start_intword_id = last_stored_intword
    end
    begin
      items = {}
      item = {}
      item_id = nil
      log "Pulling MySQL words for date #{d}, start intword #{start_intword_id}..."
      Word.find(:all, 
                :conditions => [ "scantime = ? AND intword_id >= ?", 
                                 scantime, start_intword_id],
                :order => 'intword_id, page_id').each do |w|
        # Check for interruption
        if interrupted
          exception_count = max_exception_count + 1
          raise "Interrupted"
        end
        
        # Skip if we know we can't push the word into SDB because it contains
        # funny characters.
        if unsafe_intwords.has_key?(w.intword.id)
          warn_log "Skipping intword #{w.intword.id} because it has been marked unsafe"
          next
        end

        # Compute the item unique id
        read_item_id = "#{w.intword.id}_#{w.page_id}_#{d}"
        if read_item_id == item_id
          # We are still elaborating the same item. Increase counters
          item['count'] += w.count
          item['bodycount'] += w.bodycount
          item['titlecount'] += w.titlecount
          item['keywordcount'] += w.keywordcount
          item['anchorcount'] += w.anchorcount
          item['headingcount'] += w.headingcount
        else
          # The item changed. Store the current item, if we have one and its counters
          # are over threshold.
          if item_id && worthy?(item)
            
            # Convert numbers into a lexicographically-friendly format. See:
            # http://docs.amazonwebservices.com/AmazonSimpleDB/2009-04-15/DeveloperGuide/index.html?NumericalData.html
            item['count'] = item['count'].to_s.rjust(10, '0')
            item['bodycount'] = item['bodycount'].to_s.rjust(10, '0')
            item['titlecount'] = item['titlecount'].to_s.rjust(10, '0')
            item['keywordcount'] = item['keywordcount'].to_s.rjust(10, '0')
            item['anchorcount'] = item['anchorcount'].to_s.rjust(10, '0')
            item['headingcount'] = item['headingcount'].to_s.rjust(10, '0') 
        
            items[item_id] = item
            if items.size == 25
              # We have accumulated enough items for a batch put.
              if Pulsar::Runner.dryRun?
                dry_log "Would have stored #{items.size} that look like #{items.first.inspect}"
              else
                # Send them over the wire, in replace mode.
                sdb.batch_put_attributes("Words#{scantime.year}", items, true)
              end
              
              # Increment counters and clear the items buffer
              last_stored_intword = item['id']
              count += items.size            
              log "Stored #{count} items so far..."
              items = {}
            end        
          end
      
          # Create a new fresh item. 
          # Each item contains a denormalized view of a Word, containing all the
          # usual counters, plus relational information (source, page, page kind, etc...)
          # we need because SDB is not a relational db.
          # Ensure that everything is string, apart from counters (handled separately above)
          item_id = read_item_id
          item = {}
          item['count'] = w.count
          item['bodycount'] = w.bodycount
          item['titlecount'] = w.titlecount
          item['keywordcount'] = w.keywordcount
          item['anchorcount'] = w.anchorcount
          item['headingcount'] = w.headingcount
          item['scantime'] = w.scantime.strftime('%Y-%m-%d')
          item['id'] = w.intword.id.to_s
          item['page_id'] = w.page_id.to_s
          item['page_url'] = page_map[w.page_id]['url']
          item['page_kind'] = page_map[w.page_id]['kind']
          item['name'] = w.intword.name
          item['language'] = w.intword.language.code      
        end
      end
      # Store the last item
      if item_id && worthy?(item)
        # Convert numbers into a lexicographically-friendly format. See:
        # http://docs.amazonwebservices.com/AmazonSimpleDB/2009-04-15/DeveloperGuide/index.html?NumericalData.html
        item['count'] = item['count'].to_s.rjust(10, '0')
        item['bodycount'] = item['bodycount'].to_s.rjust(10, '0')
        item['titlecount'] = item['titlecount'].to_s.rjust(10, '0')
        item['keywordcount'] = item['keywordcount'].to_s.rjust(10, '0')
        item['anchorcount'] = item['anchorcount'].to_s.rjust(10, '0')
        item['headingcount'] = item['headingcount'].to_s.rjust(10, '0') 
    
        items[item_id] = item
      end
      
      # Flush the items collected in the last iterations but not yet saved
      if items.size > 0
        if Pulsar::Runner.dryRun?
          dry_log "Would have stored #{items.size} that look like #{items.first.inspect}"
        else
          # Send them over the wire, in replace mode.
          sdb.batch_put_attributes("Words#{scantime.year}", items, true)
        end
        last_stored_intword = item['id']
        count += items.size        
        log "Stored #{count} items so far..."
        items = {}
      end
      success = true
    rescue Exception => e
      exception_count += 1
      warn_log "Uh oh, something wrong happened: #{e}"
      warn_log "Last thing I stored was: intword #{last_stored_intword}, date #{d}"
    end
  end while !success && exception_count < max_exception_count
  log success ? "Success!" : "Terminating because too many exceptions or interruption occurred."
end