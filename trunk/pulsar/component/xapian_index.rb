# = Bayes : Mean-Machine : Xapian Indexer
# The Indexer populates a Xapian instance with the informations extracted
# from a page store. Its purpose is equivalent to swarm_shoal, the
# difference being the type of backend filled with the extracted
# informations.
#
# This indexer is a ruby porting of mean-machine/bs-xapian-index.py, with
# some extra functionality.
#
# To be executed it requires a "-d" parameter to specify the directory 
# that contains the PageStore (or a portion of it) and a "-x" parameter
# to specify the path of the Xapian database. It also requires 
# access to the database, to extract page and source metadata. 
#
# For example:
#   ruby runner.rb -c swarm_shoal_options.yml \
#                  -f component/xapian_index \
#                  -d /path/to/pagestore \
#                  -x /path/to/xapian/db
#
# You can use these additional options:
#   --dryRun option for a dryRun that does not affect the Xapian database.
#   --page {pageId} option to limit the execution for a particular page.
#
# If your Xapian bindings have been installed in a non-standard location,
# include a -I option to extend the ruby include path:
#
#  ruby -I/path/to/xapian/bindings/ runner.rb ...
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
# Matteo Zandi [matteo.zandi@bayesfor.eu]
#
# == Copyright
# Copyright(c) 2009 - bayes-swarm project.
# Licensed under the GNU General Public License v22 License.

require 'xapian'
require 'tmpdir'

require 'util/log'
require 'bayes/storeiterator'

include Pulsar::Log

# Acquire some extra command line options
directory = get_opt("-d", ".")
if !File.directory?(directory)
  warn_log "#{directory} is not a valid folder."
  exit(1)
end
log "Loading pagestore from #{directory} ... "

if Pulsar::Runner.dryRun?
  xapian_db = Dir.tmpdir.chomp('/') + '/xapian'
  dry_log "Saving xapian db in temporary location #{xapian_db}"
else
  xapian_db = get_opt("-x")
  if !File.directory?(xapian_db)
    warn_log "#{xapian_db} does not exist. Will attempt to create a new Xapian db"
  else
    log "Overwriting Xapian database #{xapian_db}"
  end
end

filter_pageid = get_opt("--page")
log "Focusing on page id #{filter_pageid} ..." if filter_pageid

# Create the Xapian indexer
indexer = Xapian::TermGenerator.new

# Open the database for update, creating a new database if necessary.
database = Xapian::WritableDatabase.new(xapian_db, 
                                        Xapian::DB_CREATE_OR_OVERWRITE)

# Create an iterator to navigate the PageStore
iterator = Pulsar::StoreIterator.new

# And start working ...
iterator.each_page(directory, filter_pageid) do |scanned|
                        
  # some pages are so broken they don't even have a body. In that
  # case, fallback to the whole contents
  htmlbody = scanned.html.plain_text("/html/body")[0]
  htmlbody = scanned.html.plain_text("/html")[0] if htmlbody.nil?              
  if htmlbody.nil?
    warn_log "Nil body for page id #{scanned.p.id}, #{scanned.url}. " +
             "Check the page contents and its database config. " +
             "Maybe you configured a feed as url?"
    next
  end
  
  s_date = '%.4d%.2d%.2d' % 
           [ scanned.date.year, 
             scanned.date.month, 
             scanned.date.day ]
  dir = File.dirname(scanned.metafile)
  
  unless Pulsar::Runner.dryRun? 
    doc = Xapian::Document.new
    doc.data = scanned.url
    doc.add_value(0, scanned.language)
    doc.add_value(1, scanned.md5)
    doc.add_value(2, s_date)
    doc.add_value(3, dir)
    doc.add_value(4, scanned.p.source.id.to_s)
    doc.add_value(5, scanned.p.source.name)

    stemmer = Xapian::Stem.new(scanned.language)
    indexer.stemmer = stemmer
    indexer.document = doc

    puts "Htmlbody #{htmlbody.nil?}"
    indexer.index_text(htmlbody)

    # Add the document to the database.
    database.add_document(doc)
    log "Added to Xapian on date #{scanned.date}: #{scanned.url}"
  else
    dry_log "Saving #{scanned.url}: " + 
            "language => #{scanned.language}, hash => #{scanned.md5}, " +
            "date => #{s_date}, dir => #{dir}, " +
            "sid => #{scanned.p.source.id.to_s}, " +
            "source name => #{scanned.p.source.name}, " +
            "doc => #{htmlbody[0..100]}"
  end
end