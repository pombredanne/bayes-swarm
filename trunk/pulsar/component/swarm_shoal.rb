# = Bayes : Swarm-Shoal
# Shoal is the second component in the bayes-swarm execution chain. 
# It is responsible for loading the web pages and feeds as saved by 
# Swarm-Wave, analyzing their contents, normalizing them and saving 
# the parsed data in a relational database, suitable for access by 
# the web application.
#
# To be executed it requires a "-d" parameter to specify the directory 
# that contains the PageStore (or a portion of it). It also requires 
# access to the database, obviously.
# For example:
#   ruby runner.rb -c swarm_shoal_options.yml \
#                  -f component/swarm_shoal -d /path/to/pagestore
#
#
# You can use these additional options:
#   --dryRun option for a dryRun that does not affect the database. 
#   --page {pageId} option to limit the execution for a particular page.
#   --save-pop-stems do not save popular stems back to the database. 
# 
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

filter_pageid = get_opt("--page")
log "Focusing on page id #{filter_pageid} ..." if filter_pageid

save_popular_stems = flag?("--save-pop-stems")
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
        # +kind+ distinguishes between urls, rss feeds and rssitem
        # (single items in a Rss feed)
        md5, url, id, kind, language = l.split(" ")
        unless id                
          warn_log "Missing ids in #{metafile}. " +
                   "Maybe you didn't migrate the META file?"
          next
        end
        
        # Skip pages if a command-line filter has been specified
        next if filter_pageid && filter_pageid != id
        
        # RSS feeds are ignored. We do not parse the xml file.
        # We instead consider rssitem lines that refer to a single element
        # in a RSS feed.
        if kind == "rss"
          verbose_log "Skipping the original xml contents for Rss feed with " +
                      "id #{id}. Do not worry, its contents are still parsed."
          next
        end        
        
        # Load the page.
        # This works both for url and rssitem because rssitems share the same
        # id as their parent feed.
        p = Page.find_by_id(id)
        
        # Sanity checks
        warn_log "Page with id #{id} and url #{url} no longer exists " +
                 "in the database" unless p
        warn_log "Page with id #{id} is out-of-sync between PageStore " +
                 "and database" if p.url != url && p.kind == 'url'
        
        # Load the contents
        if p
          log "Analyzing contents for Page #{p.id}, kind: #{p.kind_name}, " +
              "url: #{p.url} on date #{metadate}"
          
          contentsfile = metafile.clone
          contentsfile[/META/] = md5 + "/contents.html"
          
          verbose_log "Opening #{contentsfile}"
          f = File.open(contentsfile)
          contents = f.read
          html = Pulsar::Html.new(contents)
          f.close
          
          # Strip out HTML Markup and apply stemming to the whole body
          stemmer = Pulsar::FerretStemmer.new
          stems = stemmer.stem(html.plain_text("/html/body")[0], 
                               p.language_name)          
          
          # Filter interesting stems and identify popular ones
          aggregator = Pulsar::StemAggregator.new
          popular_threshold = 5
          intwords_hash = Intword.get_intwords_hash(p.language_id)
          stem_hashcount = aggregator.to_stem_hashcount(stems)
                    
          # Identify interesting stems _and_ leave stem_hashcount only
          # with the non-interesting ones
          interesting_stems = aggregator.interesting_filter(stem_hashcount,
                                                            intwords_hash)

          # Cycle over the non-interesting stems and check if any of those
          # is now popular.
          popular_stems = aggregator.popularize(stem_hashcount, 
                                                popular_threshold)          
          log "Out of #{stems.size}, " +
              "#{interesting_stems.size} are interesting, and " +
              "#{popular_stems.size} are popular"              
          
          # Create the popular stems and Back-propagate IntWords enrichment
          if save_popular_stems
            Intword.save_popular_stems(popular_stems, p.language_id)
            log "#{popular_stems.size} new stems added to Intwords: " +
                " #{popular_stems}"
          end
          
          # Save results
          total_stems = interesting_stems + 
                        ( save_popular_stems ? popular_stems : [] )
          
          # title_stems = stemmer.stem(html.plain_text("//head/title")[0], p.language_name)
          # interesting_title_stems = aggregator.interesting_filter(title_stems, intwords_hash)
          
          
          total_stems.each do |stemdata|
            Word.create(:intword_id=> stemdata.id, 
                        :page_id => p.id, 
                        :scantime => metadate,
                        :count => stemdata.count)
          end
          log "#{total_stems.size} new words have been created for " +
              "page #{p.id} on date #{metadate}"
          
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

