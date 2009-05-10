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
#   --disable-cache disables intword caching
# 
#
# TODO: refactor this component to use Pulsar::StoreIterator and remove all
# the associated boilerplate
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

require 'bayes/ar'
require 'bayes/storage'
require 'bayes/blender'

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
disable_cache = flag?("--disable-cache")
warn_log "Popular stems are NOT saved into the database" if !save_popular_stems
warn_log "Intwords cache is disabled!" if save_popular_stems || disable_cache

# Prepare the intwords cache
intwords_cache = {}

# And start working ...
with_connection do |connection|
  
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
        if filter_pageid && filter_pageid != id
          log "Skipping page with id #{id}"
          next 
        end
        
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
        connection.reconnect!
        p = Page.find_by_id(id)
        
        # Sanity checks
        warn_log "Page with id #{id} and url #{url} no longer exists " +
                 "in the database" unless p
        warn_log "Page with id #{id} is out-of-sync between PageStore " +
                 "and database" if p && p.url != url && p.kind == 'url'
        
        # Load the contents
        if p
          log "Analyzing contents for Page #{p.id}, kind: #{kind}, " +
              "url: #{url} on date #{metadate}"
          
          contentsfile = metafile.clone
          contentsfile[/META/] = md5 + "/contents.html"
          
          verbose_log "Opening #{contentsfile}"
          if !File.exists?(contentsfile)
            warn_log "File #{contentsfile} does not exist. md5 incoherency?"
            next
          end
          
          f = File.open(contentsfile)
          contents = f.read
          html = Pulsar::Html.new(contents)
          f.close
          
          # Obtaining the intwords hash, either from cache or db
          # When popular stems are saved, the intwords cache cannot be
          # used, as the intwords change after every page
          if save_popular_stems || disable_cache
            intwords_hash = Intword.get_intwords_hash(p.language_id)
          else
            intwords_hash = intwords_cache[p.language_id]
            if intwords_hash.nil?
              log "Populating intwords cache for lang #{p.language_id}"
              intwords_hash = Intword.get_intwords_hash(p.language_id)
              intwords_cache[p.language_id] = intwords_hash
            end
          end
          
          blender = Pulsar::BayesBlender.new(intwords_hash)
          
          # Dismember the page into its composing stems, keeping track
          # of the specific areas of the page where they belong to
          #
          # Do not change the area names, as they map to database columns
          # in the Words table
          
          # some pages are so broken they don't even have a body. In that
          # case, fallback to the whole contents
          htmlbody = html.plain_text("/html/body")[0]
          htmlbody = html.plain_text("/html")[0] if htmlbody.nil?
          if htmlbody.nil?
            warn_log "Nil body for page id #{id}, #{url}. Check the page " +
                     "contents and its database config. " +
                     "Maybe you configured a feed as url?"
            next
          end
          
          blender.dismember(htmlbody,
                            p.language_name, # language symbol, such as :en
                            :bodycount, # area
                            7) # popular threshold
                            
          blender.dismember(html.plain_text("//head/title")[0],
                            p.language_name,
                            :titlecount,
                            1) # popular threshold
          
          blender.dismember(html.keywords.join(" "),
                            p.language_name,
                            :keywordcount,
                            1) # popular threshold
                            
          blender.dismember(html.all_plain_text("//a"),
                            p.language_name,
                            :anchorcount,
                            2) # popular threshold
                            
          headings = ""
          headings << html.all_plain_text("//h1")
          headings << html.all_plain_text("//h2")
          headings << html.all_plain_text("//h3")
          headings << html.all_plain_text("//h4")
          headings << html.all_plain_text("//h5")                                        
          blender.dismember(headings,
                            p.language_name,
                            :headingcount,
                            5) # smaller threshold for stems in headings
          
          
          # Retrieve the blended interesting stems
          interesting_stems = blender.get_interesting_stems
          popular_stems = blender.get_popular_stems

          log "On page #{p.id}: " +
              "#{interesting_stems.size} interesting, " +
              "#{popular_stems.size} popular words"              
          
          # Create the popular stems and Back-propagate IntWords enrichment
          if save_popular_stems
            unless Pulsar::Runner.dryRun? 
              Intword.save_popular_stems(popular_stems, p.language_id)
            end
            log "#{popular_stems.size} popular stems added " +
                "for language #{p.language_name} : " +
                "#{popular_stems}"
          end
          
          # Save results
          log "Saving words for page #{p.id} on #{metadate} ..."
          total_stems = interesting_stems + 
                        ( save_popular_stems ? popular_stems : [] )          
          
          saved_count = 0
          total_stems.each do |stemdata|
            saved = Word.create_stems(p.id, metadate, stemdata) do |sd|
              # We operate a minimum occurrence threshold. If a term appears
              # only once in the whole page, we do not store it, as it would
              # pollute the database.
              #
              # This is a very soft threshold. We should probably be stricter.
              sd.count_for(:bodycount) > 1 || 
              sd.count_for(:titlecount) > 0 ||
              sd.count_for(:headingcount) > 0 ||
              sd.count_for(:anchorcount) > 0 ||
              sd.count_for(:keywordcount) > 0              
              
            end
            saved_count += 1 if saved
          end
          log "#{saved_count} saved."
          
        end

      end
    end
    
  end
end

