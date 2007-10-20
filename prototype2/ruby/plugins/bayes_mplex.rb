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
require 'etl/util/ar'

# A multiplexer which iterates over all the sources defined in the <b>bayes-swarm</b> database.
# Since this multiplexer interacts with the database it requires the proper connection parameters.
class SourceMultiplexer < ETL
  include MultiplexETL
  include ARHelper
  
  def mplex(dto,context)
    dtos = Array.new  
    sources = Source.find(:all)
    log "Considering #{sources.size} sources."
    sources.each do |source|   
      cloned = deep_copy(dto)
      cloned.source = source
      dtos << cloned    
    end
    
    return dtos
  end

end

# A multiplexer which iterates over all the pages defined in the <b>bayes-swarm</b> database.
# Since this multiplexer interacts with the database it requires the proper connection parameters.
class PageMultiplexer < ETL
  include MultiplexETL
  include ARHelper
  
  def mplex(dto,context)
    pages = Page.find(:all)
    log "Considering #{pages.size} pages."
    pages.each do |url|
      cloned = deep_copy(dto)
      cloned.url = url
      dtos << cloned
    end
    
    return dtos
  end
  
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