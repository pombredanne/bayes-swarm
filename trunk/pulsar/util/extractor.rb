# = Utilities : Extractors
# Contains the available web extractors.
#
# All the extractors should conform to the following interface: they should
# provide an +extract()+ method, which takes a +page+ and returns either the
# page content, or +nil+ in case of error.
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
# Licensed under the Apache2 License.

require 'mechanize'
require 'net/http'
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'time'
require 'timeout'

require 'util/log'
require 'util/storage' # This is needed because RSS extractor directly stores its contents

module Pulsar
  
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
        return content
      rescue WWW::Mechanize::RedirectLimitReachedError
        warn_log "too many redirects from #{page.url} : #{$!}"
        nil
      rescue WWW::Mechanize::ResponseCodeError
        warn_log "unhandled return code from #{page.url} : #{$!}"
        nil
      rescue Timeout::Error
        warn_log "timeout from #{page.url}" # $! is not defined for timeouts
        nil
      end
    end
  end
  
  # An extractor for web pages that uses the plain net/http library.
  # It supports redirects, but not cookies.
  #
  # No longer use, remains here for reference only
  class HttpExtractor
    include Pulsar::Log

    def extract(page)
      begin
        response = extract_with_redirect(page.url)
        response.body
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

    def extract(rss_page)
      log "Trying: #{rss_page.url}"
      rss_content = "" # raw content of rss feed will be loaded here
      begin
        open(rss_page.url) { |s| rss_content = s.read }
      rescue
        warn_log "Unable to access feed #{rss_page.url} : #{$!}"
        return nil
      end
      
      rss = RSS::Parser.parse(rss_content, false)
      unless rss
        warn_log "RSS Parser returned a nil for #{rss_page.url}. Maybe an atom feed?"
        return nil
      end

      log "Found #{rss.items.size} items in the feed"
      new_items = 0
      rss_full_content = "" # collects content from all articles
      rss.items.each do |item|
        begin
          if !item.date
            warn_log "Feed #{rss_page.url} contains item #{item.link} with no date. Skipping"
          elsif (item.date > rss_page.last_scantime)
            log "Parsing feed element #{item.link}"
            new_items += 1
            article_url = item.link
            extractor = HttpMechanizeExtractor.new
            
            if PageStore.active?
              pageStore = Pulsar::PageStore.new # we use the plain PageStore, without extra bayes info
              pageStore.base_folder = PageStore.baseFolder
              pageStore.url = article_url
              pageStore.scantime = nil  # the same as RssPage, we don't need to save it
              # pageStore.page = page 
            end
                    
            # create a wrapper class to pass by the url in the expected format
            item_page = RssItemPage.new(article_url)
            
            cur_content = extractor.extract(item_page)
            if cur_content
              rss_full_content += cur_content
              
              pageStore.persist(cur_content) if pageStore
            end
          else
            verbose_log "skipping #{item.link} because it's too old (#{item.date})"
          end
        rescue URI::InvalidURIError
          # article_url is invalid
          warn_log "item #{item.link} in rss feed (#{rss_page.url}) appears to be invalid. Consider it for removal : $!"
        rescue TypeError, ArgumentError, NoMethodError
          # item.date might be nil
          warn_log
          log "warning, rss feed (#{rss_page.url}) contains articles with no date, consider it for removal : $!"
        end
      end
      log "#{new_items} items have been recognized as new and stored"
      return rss_full_content.size > 0 ? rss_full_content : nil
    end
  end
  
  # An utility class to wrap a +url+ into a +page+ construct
  class RssItemPage
    attr_reader :url
    def initialize(url)
      @url = url
    end
  end
  
  # A simplistic extractor that reads from local files. Used for debugging purporses only.
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
      return content
    end

  end
end