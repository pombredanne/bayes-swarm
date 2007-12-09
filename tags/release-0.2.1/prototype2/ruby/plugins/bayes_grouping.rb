# = Filtering ETL blocks for bayes-swarm
# This file contains ETL blocks specific to the bayes-swarm project.
# It contains grouping functions that compact the word list according to various algorithms
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
require 'etl/std'

class WordGroupByNameAndPosition < ETL
  def transform(dto,context)
    words = {}
    dto.words.each do |w|
      wpos = words[w.id] || words[w.word]
      if wpos.nil?
        if !w.id.nil?
          words[w.id] = { w.position => w }
        elsif !w.word.nil?
          words[w.word] = { w.position => w }
        else
          raise "Unable to find either id or name on #{w}"
        end
      else
        if !wpos[w.position].nil?
          wpos[w.position].count += w.count
          if w.tags
            wpos[w.position].tags = wpos[w.position].tags.concat(w.tags)
          end
        else
          wpos[w.position] = w
        end
      end
    end
    
    res = []
    words.each_pair { |key,wpos| res = res.concat(wpos.values)}
    dto.words = res
  end
end