# = Multiplex ETL blocks for bayes-swarm
# This file contains ETL blocks specific to the bayes-swarm project.
# It contains multiplexers which scan through pages and sources.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
require 'etl/std'
require 'etl/mplex'
require 'etl/util/db'

# A multiplexer which iterates over all the sources defined in the <b>bayes-swarm</b> database.
# Since this multiplexer interacts with the database it requires the proper connection parameters.
class SourceMultiplexer < ETL
  include MultiplexETL
  include DatabaseHelper
  
  def mplex(dto,context)
    dtos = Array.new  
    with_connection(@props) do 
      get_sources.each do |source|   
        cloned = deep_copy(dto)
        cloned.source = source
        dtos << cloned
      end
    end
    
    return dtos
  end
  
  def get_sources
    sources = []
    @conn.query("SELECT id,name FROM sources") do |res|
      while row = res.fetch_row do
        sources << row[1]
      end
    end
    return sources
  end
  private :get_sources
end

# A multiplexer which iterates over all the pages defined in the <b>bayes-swarm</b> database.
# Since this multiplexer interacts with the database it requires the proper connection parameters.
class PageMultiplexer < ETL
  include MultiplexETL
  include DatabaseHelper
  
  def mplex(dto,context)
    dtos = Array.new  
    with_connection(@props) do 
      get_pages(dto.source).each do |url|   
        cloned = deep_copy(dto)
        cloned.url = url
        dtos << cloned
      end
    end
    
    return dtos
  end
  
  def get_pages(source)
    urls = []
    @conn.query("SELECT p.url FROM PAGES p, SOURCES s where p.source_id = s.id AND s.name = '#{source}' ") do |res| 
      while row = res.fetch_row do
        urls << row[0]
      end
    end
    return urls
  end
  private :get_pages
end

# A multiplexer which iterates over all the files contained in a given directory.
# The returned DTOs will have the +source+ set to the directory path and the +url+ set to absolute
# file path. It detects the folder to scan from the +folder+ property, which must be present within the 
# ETL block configuration. 
class LocalFileMultiplexer < ETL
  include MultiplexETL
  
  def mplex(dto,context)
    dtos = Array.new
    folder = @props["folder"]
    Dir.new(folder).each do |filename|
      if File.file?(folder + "/" + filename)
        cloned = deep_copy(dto)
        cloned.source = folder
        cloned.url = folder + "/" + filename
        dtos << cloned
      end
    end
    return dtos
  end
end