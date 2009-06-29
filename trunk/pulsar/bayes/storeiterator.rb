# = Bayes : StoreIterator
# Use a StoreIterator to navigate the contents of a Pagestore, or a portion
# of it. It takes care of all the boilerplate code involved, and handles
# the details of PageStore structure ( as described in 
# http://code.google.com/p/bayes-swarm/wiki/FileStorage ), abstracting them to
# the caller.
#
# To use it, just create a new +StoreIterator+ and invoke +each_page()+ with
# the required parameteres. +each_page()+ yields for each page found, so you
# can implement your handling logic.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2009 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

require 'util/log'
require 'util/lister'
require 'util/ar'
require 'util/html'

require 'bayes/ar'
require 'bayes/storage'

module Pulsar
  
  # Iterates over a PageStore
  class StoreIterator
    include Pulsar::Log
    include Pulsar::AR
   
    # Iterates over all the pages found in +directory+ and yields for each
    # one found.
    #
    # +directory+ should be a PageStore root folder or a subfolder. If you provide
    # a subfolder (for example /pagestore/2008/12/25/ ) the iterator will
    # consider only the pages found in that portion of the PageStore.
    #
    # Pass +filter_pageid+ if you want to limit the iteration only to a specific
    # page.
    # 
    # The method yields back for every page found. Each page may be yielded
    # multiple times, as it may have been recorded in the PageStore at multiple
    # dates.
    # 
    # The handling block receives a +ScannedPage+ as its single parameter.
    # Refers to its documentation for further info.
    #
    # This method takes care of all the error handling and exceptional conditions
    # that may occur while iteratating over the PageStore:
    #   * corrupt metafiles
    #   * PageStore-database incoherency
    #   * unhandled exceptions in the yield block
    # 
    # The iterator reports each problem found in the logs and moves to the next
    # entry. It yields only if the entry is valid, so the number of yields
    # may be different from the number of pages in the PageStore.
    #
    # This method tries to open a connection to the pages database (usually
    # maintained by +swarm_shoal+ to fetch additional info).
    #
    # This method iterates only over +url+ and +rssitem+ types, skipping all
    # +rss+ entries found in the PageStore.
    #
    def each_page(directory, filter_pageid=nil)
      # Open a database connection ...
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
                
                begin
                  yield ScannedPage.new(md5, url, kind, language, 
                                        p, html, metadate, metafile)
                rescue
                  warn_log "Unhandled expection for page id #{id}, #{url} : #{$!}"
                end  # exception rescue
              end  # Page found on the db
            end  # each line in META
          end  # close META file
        end  # META file lister
      end  # dataabase connection     
    end  # each_page method
     
  end # MetaScanner class
  
  # A ScannedPage represents a single instance of page found in a PageStore
  # and relative to a single scan date.
  # It contains the following informations:
  #
  #   * url: a string with the URL this page refers to
  #   * date: the date this page was saved at (also called +scantime+)
  #   * html: a Pulsar::Html instance containing the html contents of the page
  #           as they were at the scantime.
  #   * p: the ActiveRecord Page this scanned info belong to. Note that in the
  #        the case of +rssitem+ entries, +p+ refers to the master RSS feed.
  #   * kind: the page kind (either +url+ or +rssitem+)
  #   * langauge: the page language (in ISO-639-1 format)
  #   * md5: the md5 hash of the page url. This infomartion is part of the
  #          PageStore underlying structure
  #   * metafile: the META file this page was found in  
  #
  class ScannedPage
    attr_reader :md5, :url, :kind, :language, :p, :html, :date, :metafile
    
    def initialize(md5, url, kind, language, p, html, date, metafile)
      @md5 = md5
      @url = url
      @kind = kind
      @language = language
      @p = p
      @html = html
      @date = date
      @metafile = metafile
    end
  end
end # Pulsar module
