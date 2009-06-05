# = Utilities : Extractors
# Contains the available web extractors.
#
# All the extractors should conform to the following interface: they should
# provide an +extract()+ method, which takes a +page+ and returns
# an +ExtractedPage+, a wrapper that binds together a page and its content, 
# or +nil+ in case of error.
#
# A +page+ is whatever object that exposes the following parameters:
# [url] the page source url.
# [last_scantime] when the page was last scanned by bayes-swarm.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

require 'mechanize'
require 'net/http'
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'time'
require 'timeout'

require 'util/log'
require 'util/rsspage'

module Pulsar
  
  # Wrapper class for a page and its associated content.
  # A page on its own just contains its +url+ and +last_scantime+ .
  # A page may contain subpages (as is the case for RSS feeds).
  # Subpages are just a list of +ExtractedPage+s like their parent one.
  class ExtractedPage
    attr_reader :page, :subpages
    attr_accessor :content
    
    def initialize(page, content="")
      @page = page
      
      # content is never nil. At most empty
      @content = content.nil? ? "" : content
      @subpages = []
    end
    
    def add_subpage(subpage)
      @subpages << subpage
    end
  end
    
  # An extractor for web pages that uses the WWW::Mechanize library.
  # It supports redirects and cookies.
  class HttpMechanizeExtractor
    include Pulsar::Log
    
    def extract(page)
      log "Trying #{page.url}"
      agent = WWW::Mechanize.new
      begin
        content = nil
        Timeout::timeout(20) do
          response = agent.get(page.url)
          content = response.content
        end
        return ExtractedPage.new(page, content)
      rescue WWW::Mechanize::RedirectLimitReachedError
        warn_log "too many redirects from #{page.url} : #{$!}"
        nil
      rescue WWW::Mechanize::ResponseCodeError
        warn_log "unhandled return code from #{page.url} : #{$!}"
        nil
      rescue Timeout::Error
        warn_log "timeout from #{page.url}" # $! is not defined for timeouts
        nil
      rescue Timeout::ExitException
        warn_log "timeout from #{page.url}"
        nil        
      end
    end
  end
  
  # An extractor for web pages that uses the plain net/http library.
  # It supports redirects, but not cookies.
  #
  # No longer used, remains here for reference only
  class HttpExtractor
    include Pulsar::Log

    def extract(page)
      begin
        response = extract_with_redirect(page.url)
        ExtractedPage.new(page, response.body)
      rescue
        warn_log "unable to extract contents from #{page.url} : #{$!}"
        nil
      end
    end

    def extract_with_redirect(url, limit=10, try=1)
      fail "http redirect too deep" if limit.zero?
      fail "timeout, aborting." if (try>10)

      begin
        log "Trying (#{try}): #{url}"
        response = Net::HTTP.get_response(URI.parse(url))
        case response
        when Net::HTTPSuccess
          response
        when Net::HTTPRedirection
          loc = response['location']
          unless loc =~ /^https?:\/\//
            # location is relative to the domain base
            prev_uri = URI.parse(url)
            loc = "/#{loc}" unless loc =~ /^\//
            loc = "#{prev_uri.scheme}://#{prev_uri.host}:#{prev_uri.port}#{loc}"
          end
          log "Redirecting to: #{loc}"
          extract_with_redirect(loc,limit-1)
        else
          fail "Unhandled response code #{response.code}"
        end
      rescue Timeout::Error
        log "Timeout error, retrying.."
        extract_with_redirect(url, limit=limit, try=try+1)
      end    
    end

  end

  # An extractor for RSS feeds. It is smart enough to elaborate only feed
  # items that have been added since the last time.
  #--
  # TODO(battlehorse): I guess this cripples the extractor a bit if you
  # don't parse rss feeds on a daily basis, since we use the current day
  # as returned by Time.now to save the feed contents in the database.
  class RssExtractor
    include Pulsar::Log    

    def extract(rss_feed)
      log "Trying: #{rss_feed.url}"
      
      # Load the RSS feed
      rss_content = ""
      begin
        # open-uri augments Kernel with open()
        open(rss_feed.url) { |s| rss_content = s.read }
      rescue
        warn_log "Unable to access feed #{rss_feed.url} : #{$!}"
        return nil
      end
      
      # Prepare the result extracted page
      extracted_feed = ExtractedPage.new(rss_feed, rss_content)
      
      # Parse the RSS feed, but skip rss validation
      do_validate = false
      rss = RSS::Parser.parse(rss_content, do_validate)
      unless rss
        warn_log "RSS Parser returned a nil for #{rss_feed.url}. " +
                 "Maybe an atom feed?"
        return nil
      end

      log "Found #{rss.items.size} items in the feed"
      rss.items.each do |item|
        begin
          if !item.date
            warn_log "Feed #{rss_feed.url} contains item #{item.link} " +
                     "with no date. Skipping"
          elsif (item.date > rss_feed.last_scantime)
            log "Parsing feed element #{item.link}"            
            
            # create a page representing the single rss item
            item_page = Pulsar::RssItemPage.new(item.link, rss_feed.id, 
                                                rss_feed.language_name)
            
            extractor = HttpMechanizeExtractor.new        
            extracted_item = extractor.extract(item_page)
            
            # Add the new item to the list of rss items
            extracted_feed.add_subpage(extracted_item) if extracted_item
          else
            verbose_log "skipping #{item.link} " +
                        "because it's too old (#{item.date})"
          end
        rescue URI::InvalidURIError
          # item.link is invalid
          warn_log "item #{item.link} in rss feed (#{rss_feed.url}) appears " +
                   "to be invalid. Consider it for removal : $!"
        rescue TypeError, ArgumentError, NoMethodError
          # item.date might be nil
          warn_log "warning, rss feed (#{rss_feed.url}) contains articles " +
                   "with no date, consider it for removal : $!"
        end
      end
      log "#{extracted_feed.subpages.length} items have been recognized " + 
          "as new (later than #{rss_feed.last_scantime}) and stored"    
      return extracted_feed
    end
  end
  
  # A simplistic extractor that reads from local files. 
  # Used for debugging purporses only.
  class FileExtractor
    include Pulsar::Log    

    def extract(page)
      log "Trying: #{page.url}"
      content = ""
      File.open(page.url) do |file|
        while line = file.gets
          content << " " << line
        end
      end
      return ExtractedPage.new(page, content)
    end

  end
end
