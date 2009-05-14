# = Bayes : Blender
# Contains the bulk logic that transforms a plain text content
# into a set of data-structures suitable for storage in the 
# bayes database.
#
# Given a text content that belongs to a given portion of a page, it 
# performs the following operations:
#   * stopwords and other language artifacts are filtered
#   * the content is stemmed according to the language
#   * identifies 'interesting' tokens (aka, tokens we want to keep track of)
#   * identifies 'popular' tokens (aka, tokens that occur frequently enough
#     to qualify as interesting)
#   * merges the single tokens extracted from different parts of the
#     content (such as titles, anchors and body text) into a single
#     token stream (hence the blending)
#   * and finally returns two lists: popular tokens to be added to the
#     interesting list and tokens to be associated with the page
#
# This module relies on functionalities provided by other lower level modules,
# such as +Pulsar::FerretStemmer+, +Pulsar::StemAggregator+, and others.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

require 'set'
require 'util/log'
require 'util/stemmer'

module Pulsar
  
  class StemData
    # Enriches the +StemData+ class used by the stemmer with extra
    # info about _where_ the data belongs to.
    
    # +page_area+ is a set of symbols, each one describing an area where
    # the StemData has been found.
    attr_accessor :page_area, :area_count
    
    def to_s
      "#{@stem} (id: #{@id}, occ: #{@count}, area_count: #{@area_count})"
    end
    
    def count_for(area)
      area_count[area] || 0
    end
  end
  
  class BayesBlender
    
    def initialize(intwords_hash) 
      @intwords_hash = intwords_hash
      @stemmer = Pulsar::FerretStemmer.new
      @aggregator = Pulsar::StemAggregator.new
      
      @global_interesting = {}
      @global_popular = {}
    end
    
    def dismember(content, language_name, page_area, popular_threshold)
      if content.nil? || content.strip.length == 0
        verbose_log "Received empty content. Skipping."
        return
      end
      
      stems = @stemmer.stem(content, language_name)
      stem_hashcount = @aggregator.to_stem_hashcount(stems)
                
      # Identify interesting stems _and_ leave stem_hashcount only
      # with the non-interesting ones
      interesting_stems = @aggregator.interesting_filter(stem_hashcount,
                                                         @intwords_hash)

      # Enrich the interesting_stems with the area they belong to
      interesting_stems.each do |stemdata| 
        stemdata.page_area = Set.new
        stemdata.page_area << page_area
        
        stemdata.area_count = { page_area => stemdata.count}
      end

      # Cycle over the non-interesting stems and check if any of those
      # is now popular.
      popular_stems = @aggregator.popularize(stem_hashcount, 
                                             popular_threshold)

      blend(@global_interesting, interesting_stems) { |stemdata| stemdata.id }
      
      # popular items do not have an id (yet)
      blend(@global_popular, popular_stems) { |stemdata| stemdata.stem }
    end
    
    def get_interesting_stems
      return @global_interesting.values
    end
    
    def get_popular_stems
      return @global_popular.values
    end
    
    def blend(global_hash, new_data)
      new_data.each do |stemdata|
        key = yield stemdata
        global_stemdata = global_hash[key]
        if global_stemdata.nil?
          
          # Create a new entry in the global hash with a 
          # copy of the received stemdata
          global_stemdata = Pulsar::StemData.new(stemdata.stem, 
                                                 0,
                                                 stemdata.id)

          global_stemdata.page_area = Set.new
          global_stemdata.area_count = Hash.new
          
          # And put it in the global list
          global_hash[key] = global_stemdata
        end
        
        # Merge the current stemdata
        # Set.merge changes the original object, while Hash.merge doesn't. Doh!
        global_stemdata.count += stemdata.count
        
        unless stemdata.page_area.nil?
          global_stemdata.page_area.merge(stemdata.page_area) 
        end
        
        unless stemdata.area_count.nil?
          global_stemdata.area_count = global_stemdata.area_count.
                                          merge(stemdata.area_count)   
        end
      end
    end
  end
end
