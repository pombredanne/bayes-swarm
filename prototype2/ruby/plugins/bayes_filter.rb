# = Filtering ETL blocks for bayes-swarm
# This file contains ETL blocks specific to the bayes-swarm project.
# It contains filters that reduce the word list according to various algorithms
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
require 'etl/std'

# This filter excludes all the words which do not appear in the list of interesting words (int_word list)
class InterestingFilter < ETL
  def transform(dto,context)
    int_words = context[:int_words]
    dto.words.reject! do |word|
      found = false
      int_words.each do |int_word|
        if int_word[:name] == word.word
          word.id = int_word[:id] # enrich the word with its id, since we have matched it
          found = true
          break
        end
      end
      return found
    end
  end
  
end