# = Extractor ETL blocks for bayes-swarm
# This file contains ETL blocks specific to the bayes-swarm project.
# It contains extractors that can download pages from the file or load them from filesystem
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'etl/std'
require "net/http"

# This extractor downloads remote pages (via the http protocol) and stores their
# content in context with the <tt>raw_content</tt> key. It follows redirects if needed.
# It relies upon the +url+ variable of the DTO to identify the remote url to use
class HttpExtractor < ETL
  
  def extract(dto,context)
   response = extract_with_redirect(get_url(dto,context))
   context[:raw_content] = response.body
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
  private :extract_with_redirect
  
  def get_url(dto,context)
    if dto.url
      dto.url
    elsif context[:url]
      context[:url]
    else
      raise "Unable to find url to extract"
    end
  end
  private :get_url
  
end

# This extractor load files from the local filesystem and stores their
# content in context with the <tt>raw_content</tt> key. It follows redirects if needed
# It relies upon the +url+ variable of the DTO to identify the file to load
class FileExtractor < ETL
  
  def extract(dto,context)
    context[:raw_content] = parse_file(dto,context)
  end
  
  def parse_file(dto,context)
    content = ""
    File.open(get_filename(dto,context)) do |file| 
      while line = file.gets 
        content << " " << line 
      end 
    end
    return content    
  end
  
  def get_filename(dto,context)
    if dto.url
      dto.url
    elsif context[:url]
      context[:url]
    else
      raise "Unable to find url to extract"
    end
  end
    
end