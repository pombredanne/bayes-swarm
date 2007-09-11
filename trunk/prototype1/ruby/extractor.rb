require "net/http"
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'

class HttpExtractor
  
  def extract(url)
   response = extract_with_redirect(url)
   response.body
  end
  
  def extract_with_redirect(url, limit=10)
    fail "#{self.class.name}: http redirect too deep" if limit.zero?
    puts "#{self.class.name}: Trying: #{url}"
    response = Net::HTTP.get_response(URI.parse(url))
    case response
    when Net::HTTPSuccess
      response
    when Net::HTTPRedirection
      extract_with_redirect(response['location'],limit-1)
    else
      response.error!
    end
  end
  
end

class RssExtractor

  def extract(rss_page)
    rss_content = "" # raw content of rss feed will be loaded here
    open(rss_page) do |s| rss_content = s.read end
    rss = RSS::Parser.parse(rss_content, false)

    rss_full_content = "" # collects content from all articles
    rss.items.each do |item|
       article_url = item.link
       extractor = HttpExtractor.new
       rss_full_content += extractor.extract(article_url)
    end
    return rss_full_content
  end
  
end

class FileExtractor
  
  def extract(filename)
    content = ""
    File.open(filename) do |file| 
      while line = file.gets 
        content << " " << line 
      end 
    end
    return content
  end
  
end
