# = Storage and Load ETL blocks for bayes-swarm
# This file contains ETL blocks specific to the bayes-swarm project.
# It contains blocks that may be used to store DTOs into various output destinations
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
require 'etl/std'

# Stores the current DTO in a CSV formatted file. The file name can be specified
# with the +filename+ configuration property, otherwise a default will be used.
class CSVLoader < ETL
  def load(dto,context)
    fname = @props["filename"] ||= "etl_output.csv"
    mplex_fname = fname.gsub(/\.csv/,"_#{rand(1000)}.csv") # FIXME: hack to work around overwrites due to mplexed invocations
    File.open(mplex_fname,"w") do |f|
      f.puts "id,word,count,url,source,scantime"
      dto.words.each do |word|
        f.puts "#{word.id},\"#{word.word}\",#{word.count},\"#{word.position}\",\"#{dto.url}\",\"#{dto.source}\",\"#{dto.scantime}\""
      end
    end
  end
  
end