# = Bayes : Swarm-Shoal
# Shoal is the second component in the bayes-swarm execution chain. It is
# responsible for loading the web pages and feeds as saved by Swarm-Wave, analyzing
# their contents, normalizing them and saving the parsed data in a relational
# database, suitable for access by the web application.
#
# To be executed it requires a "-d" parameter to specify the directory that contains the
# PageStore (or a portion of it). It also requires access to the database, obviously.
# For example:
#   ruby runner.rb -c swarm_shoal_options.yml -f component/swarm_shoal -d /path/to/pagestore
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'util/log'
require 'util/lister'
require 'util/ar'
require 'util/html'
require 'util/stemmer'

require 'bayes/ar'
require 'bayes/storage'

include Pulsar::Log
include Pulsar::AR

# Acquire some extra command line options
directory = get_opt("-d", ".")
if !File.directory?(directory)
  warn_log "#{directory} is not a valid folder."
  exit(1)
end
log "Loading pagestore from #{directory} ... "

filter_pageid = get_opt("-p")
log "Focusing on page id #{filter_pageid} ..." if filter_pageid

save_popular_stems = get_opt("--save-pop-stems").nil? || get_opt("--save-pop-stems") == "true"
warn_log "Popular stems are NOT saved into the database" if !save_popular_stems

# And start working ...
with_connection do
  
  # Extract all the top-level META files
  lister = Pulsar::Lister.new(directory, /META$/)
  lister.extract.each do |metafile|
    metadate = Pulsar::PageStore.dateFromMeta(metafile)
    
    # Open the META file to get a grasp of what the pagestore contains
    log "Opening #{metafile}. Affected date is #{metadate}"
    File.open(metafile, "r") do |f|
      f.each_line do |l|
        
        # Each line in the META file represents a store page
        # (or composition of pages, just like in RSS feeds)
        md5, url, id, kind, language = l.split(" ")
        unless id
          
          #TODO(battlehorse): more likely, we have found the META file for an RSS feed ...
          warn_log "Missing ids in #{metafile}. Maybe you didn't migrate the META file?"
          next
        end
        
        # Skip pages if a command-line filter has been specified
        next if filter_pageid && filter_pageid != id
        
        # Load the page
        p = Page.find_by_id(id)
        
        # Sanity check
        warn_log "Page with id #{id} and url #{url} no longer exists in the database" unless p
        warn_log "Page with id #{id} is out-of-sync between PageStore and database" unless p.url == url
        
        # Load the contents
        if p
          log "Analyzing contents for Page #{p.id}, url: #{p.url} on date #{metadate}"
          
          contentsfile = metafile.clone
          contentsfile[/META/] = md5 + "/contents.html"
          f = File.open(contentsfile)
          contents = f.read
          html = Pulsar::Html.new(contents)
          f.close
          
          # Strip out HTML Markup and apply stemming to the whole body
          stemmer = Pulsar::FerretStemmer.new
          stems = stemmer.stem(html.plain_text("/html/body")[0], p.language_name)          
          
          # Filter interesting stems and identify popular ones
          aggregator = Pulsar::StemAggregator.new
          intwords_hash = Intword.get_intwords_hash(p.language_id)
          interesting_stems = aggregator.interesting_filter(stems, intwords_hash)
          popular_stems = aggregator.popularize(stems, 5)          
          log "Interesting title stems : #{interesting_title_stems}"
          
          # Create the popular stems and Back-propagate IntWords enrichment
          if save_popular_stems
            Intword.save_popular_stems(popular_stems, p.language_id)
            log "#{popular_stems.size} new stems have been added to Intwords : #{popular_stems}"
          end
          
          # Save results
          total_stems = interesting_stems + ( save_popular_stems ? popular_stems : [] )
          
          # title_stems = stemmer.stem(html.plain_text("//head/title")[0], p.language_name)
          # interesting_title_stems = aggregator.interesting_filter(title_stems, intwords_hash)
          
          
          total_stems.each do |stemdata|
            Word.create(:intword_id=> stemdata.id, 
                        :page_id => p.id, 
                        :scantime => metadate,
                        :count => stemdata.count)
          end
          log "#{total_stems.size} new words have been created for page #{p.id} on date #{metadate}"
          
          # Eventually identify specific parts of the page ( headings, links, titles etc... ? )
          # html.plain_text("//title").each { |a| puts "== #{a} ==" }
          # html.plain_text("//h1").each { |a| puts "== #{a} ==" }
          # html.plain_text("//h2").each { |a| puts "== #{a} ==" }
          # html.plain_text("//h3").each { |a| puts "== #{a} ==" }
          # html.plain_text("//h4").each { |a| puts "== #{a} ==" }
          # html.plain_text("//h5").each { |a| puts "== #{a} ==" }                                                  
          # html.plain_text("//a").each { |a| puts "== #{a} ==" }
        end

      end
    end
    
  end
end

