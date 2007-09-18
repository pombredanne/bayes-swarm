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
require 'etl/util/log'
require 'ferret'

# This filter applies stemming rules to all the words in the current DTO
class StemFilter < ETL
  
  def transform(dto, context)
    # FIXME: stemming happens one word at a time. Should process the whole contents as a stream?
    dto.words.each { |w| w.word = stem(w.word,:eng).join(" ")}
  end
  
  def stem(content, lang)
    stopwords = {:ita => Ferret::Analysis::FULL_ITALIAN_STOP_WORDS,
             :eng => Ferret::Analysis::EXTENDED_ENGLISH_STOP_WORDS}
  
    analyzer = StopAndStemAnalyzer.new
    stream = analyzer.token_stream(nil, content, stopwords[lang])
    token = stream.next
    res = []
    until token.nil?
      res << token.text
      token = stream.next
    end
    
    # filter out stems which are too short or plain numbers
    res.reject! { |s| s.nil? || s.length <= 2 || s =~ /\d+/ }
    
    return res
  end
  private :stem
end

# A Ferret analyzer which applies in sequence various filters, including stemming and
# a stop-word filtering
class StopAndStemAnalyzer < Ferret::Analysis::Analyzer
  include Ferret::Analysis
  
  def token_stream(field, str, stopwords)
    return StemFilter.new(StopFilter.new(LowerCaseFilter.new(StandardTokenizer.new(str)), stopwords))
  end
end

# This filter excludes all the words which do not appear in the list of interesting words (int_word list)
class InterestingFilter < ETL
  include Log
  
  def transform(dto,context)
    int_words = context[:int_words]
    dto.words.reject! do |word|
      found = false
      int_words.each do |int_word|
        if int_word[:name] == word.word
          word.id = int_word[:id] # enrich the word with its id, since we have matched it
          if verbose?
            verbose_log("Matched interesting word #{word.word} (id=#{word.id})")
          end
          
          found = true
          break
        end
      end
      return found
    end
  end
  
end