# = Extract ETL blocks
# This file contains ETL blocks that can perform the *extract* phase of an ETL process.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
require 'etl/std'

class Initializer < ETL
  def extract(dto,context)
    dto.url = context[:url]
    dto.scantime = context[:scantime] || Time.now
    dto.source = context[:source] || get_host(dto.url) || "unknown source"
  end
  
  def get_host(url)
    url_regex = Regexp.new("http[s]?://(.*\..*)(/.*)?")
    if url =~ url_regex
      $1
    else
      nil
    end
  end
end

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
      
    else
      raise "Unable to find url to extract"
    end
  end
    
end