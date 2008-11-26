# = Extract ETL blocks
# This file contains ETL blocks used for testing purposes. Its content are
# subject to change without notice.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
require 'etl/std'
require 'etl/mplex'
require 'etl/util/log'

class TestETL < ETL
  def extract(dto, context)
    dto.source = "http://news.google.com"
    dto.url = "http://news.google.com/news"
    dto.scantime = Time.at(0)
    dto.words = Array.new
    (1..5).each { |i| dto.words << WordDTO.new("word#{i}", "title", i) }
  end
end

class TestMplexedInvokeETL < ETL
  def extract(dto,context)
    puts "extracting #{dto.source} , #{dto.url}"
  end
  def transform(dto,context)
    puts "transforming #{dto.source},  #{dto.url}"
  end
  def load(dto,context)
    puts "loading #{dto.source}, #{dto.url}"
  end
end

class MartinETL < ETL
  include Log
  def transform(dto,context)
    log "Martin ETL is running!"
    dto
  end
end

class ItalyETL < ETL
  include Log
  def transform(dto,context)
    log "Italy ETL is running!"
    dto
  end
end

class TestCondETL < ConditionETL
  include Log
  def run?(block,dto,context)
    log "Testing condition for #{block.name} and #{dto.url}"
    r = Regexp.new(block.name)
    dto.url =~ r
  end
end

class TestMultiplexETL < ETL
  include MultiplexETL
  
  def mplex(dto,context)
    dtos = Array.new
    (1..5).each do |i|
      cloned = deep_copy(dto)
      cloned.source = "#{dto.source}_#{i}"
      dtos << cloned
    end
    
    return dtos
  end
end