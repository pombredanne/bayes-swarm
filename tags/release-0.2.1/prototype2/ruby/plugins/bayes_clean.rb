# = Cleaning ETL blocks for bayes-swarm
# This file contains ETL blocks specific to the bayes-swarm project.
# It contains extractors that clean raw contents from the previous steps.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'etl/std'
require 'dto/dto'

class StripTagsAndEntities < ETL
  
  def transform(dto,context)
    raw_word_list = strip_tags_and_entities(context[:raw_content]).split
    dto.words ||= []
    raw_word_list.each { |w| dto.words << WordDTO.new(nil,w,"global",1)}
  end
  
  def strip_tags_and_entities(content = "")
    one_liner = ""
    content.each_line do |line|
      one_liner += line.chomp + " "
    end
    one_liner.gsub(/<.*?>/,"").gsub(/&.*?;/," ")
  end
  private :strip_tags_and_entities
end