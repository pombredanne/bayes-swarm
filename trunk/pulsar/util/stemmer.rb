# = Utilities : Stemmer
# The Stemmer is responsible for cleaning up textual data. It performs three
# basic operations:
# * stemming the words found within a block of text.
# * removing stopwords ( very popular words such as conjunctions) from the sample
# * removing special characters such as quotation marks, question marks and so on.
#
# All the above operations are supported in different languages.
#
# == Author
# Matteo Zandi [matteo.zandi@bayesfor.eu]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'ferret'

module Pulsar
  
  # A simple definition for a stem, that tracks its name, the number 
  # of occurrences within a given domain (e.g. a webpage) and its 
  # id (to link it back to the database)
  class StemData
    attr_accessor :stem , :count, :id

    def initialize(stem, count, id)
      @stem = stem
      @count = count
      @id = id
    end
    
    def to_s
      "#{@stem} (id: #{@id}, occ: #{@count})"
    end
  end  
  
  # Supports the definition of custom lists of stopwords, to be used by 
  # the stemmer.
  class CustomLists
    
    def initialize
      @langs = [:it, :en] # list of supported languages
    end

    # Returns the ferret standard stopwords lists for italian and english
    def ferret_stopwords
      return {:it => Ferret::Analysis::FULL_ITALIAN_STOP_WORDS,
              :en => Ferret::Analysis::EXTENDED_ENGLISH_STOP_WORDS}
    end

    # Returns a customized list of stopwords. This list is generated
    # by removing a custom list of stopwords (as read from the 
    # configuration file under the +keep_stopwords+ key) from the 
    # +ferret_stopwords+ list.
    def custom_stopwords
      stopwords_to_keep = Pulsar::Runner.opts['keep_stopwords']

      result = {}
      @langs.each do |lang|
        result[lang] = ferret_stopwords[lang].reject do |word| 
          stopwords_to_keep[lang].include?(word)
        end
      end

      result
    end    
  end
  
  # Performs stemming and stopwords removal from a +content+. 
  # Operates in multiple languages.
  class FerretStemmer
    def initialize    
      @stopwords_lists = Pulsar::CustomLists.new.custom_stopwords
    end

    def stem(content, lang)
      analyzer = Pulsar::StopAndStemAnalyzer.new
      stream = analyzer.token_stream(nil, content, lang, @stopwords_lists[lang])
      token = stream.next
      res = []
      until token.nil?
        res << token.text
        token = stream.next
      end

      return res
    end

  end

  # The stemming and stopwords filter internally used by +FerretStemer+. 
  # *NOTE* that it does not apply stemming to the italian language. 
  # It has been found in the past that results are better this way.
  class StopAndStemAnalyzer < Ferret::Analysis::Analyzer
    include Ferret::Analysis

    def token_stream(field, str, lang, stopwords)
      if lang == :it
        return StopFilter.new(LowerCaseFilter.new(StandardTokenizer.new(str)), 
                              stopwords)
      else
        return StemFilter.new(
                 StopFilter.new(LowerCaseFilter.new(StandardTokenizer.new(str)),
                 stopwords))
      end
    end
  end
  
  # Aggregates and filters stems according to various criteria. For example,
  # it groups stems by popularity and filters them according to custom lists.
  class StemAggregator
    
    # Filters a list of stems depending on a custom list of "interesting" stems
    # that have to be preserved.
    # 
    # +stem_hashcount+ is an hash of stems to be filtered. Each key is 
    #     a stem, while the value is a +StemData+ object.
    # +intwords_hash+ is an hash that associates a stem with its database id.
    #
    # It returns a list of Pulsar::StemData objects, filtered according to the 
    # "interesting" list and ordered by occurrences count desc.
    #
    # *NOTE* that this method has also the side effect of removing
    # interesting items from +stem_hashcount+, so what's left after 
    # execution are only the non-interesting stems.
    #--
    # TODO(battlehorse): it's probably better to provide 2 returned values
    # and leave the input parameters untouched.
    def interesting_filter(stem_hashcount, intwords_hash)      
      int_stems_found = Array.new

      stem_hashcount.each do |stem,stemdata|
        
        # check if it is among interesting stems
        if intwords_hash.has_key?(stem)
          stemdata.id = intwords_hash[stem]
          int_stems_found << stemdata
          
          # delete current stem from list
          stem_hashcount.delete(stem)
        end
      end
      int_stems_found = int_stems_found.
                            sort_by { |stemdata| stemdata.count }.
                            reverse
      return int_stems_found
    end
    
    # Filters a list of stems to identify the popular ones. Popular stems
    # represent a feedback loop as they ultimately turn into the "interesting" 
    # list tha filters stems in first place.
    #
    # +stem_hashcount+ is an hash of stems to be filtered. Each key is 
    #     a stem, while the value is a +StemData+ object.
    # +threshold+ is a number representing the minimum number of stem 
    #     occurrences to qualify it as popular.
    #
    # It returns a list of Pulsar::StemData objects that are recognized as
    # popular. The list if ordered by occurrences count desc.
    def popularize(stem_hashcount, threshold)
      popular_stems_found = stem_hashcount.values
      
      # Applies various filters to prune irrelevant stems.
      popular_stems_found = popular_stems_found.
        select { |stemdata| stemdata.stem.length > 2 }. # stem not too short
        select { |stemdata| stemdata.stem !~ /\d+/ }. # No numbers please
        select { |stemdata| stemdata.count > threshold } # over threshold
        
      popular_stems_found.sort_by { |stemdata| stemdata.count }.reverse
      return popular_stems_found
    end
        
    # Converts a list of stems into an hash that associate each stem to a
    # +StemData+ structure, that contains also the occurrences count
    def to_stem_hashcount(stems)
      stem_hash = Hash.new
      stems.each do |stem|
        stem_hash[stem] ||= Pulsar::StemData.new(stem, 0, nil)
        stem_hash[stem].count += 1
      end
      return stem_hash
    end
    
  end
  
end