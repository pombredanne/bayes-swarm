# = Helper ETL blocks for bayes-swarm
# This file contains ETL blocks specific to the bayes-swarm project.
# It contains helper and utility blocks 
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
require 'etl/std'
require 'etl/util/ar'

# This block loads the list of interesting words and stores it into the context under
# the key <tt>:int_words</tt> as an array of hashes. Each hash will have the +id+ and +name+ keys
# referring to the same properties of each loaded int_word.
class IntWordInitializer < ETL
  include ARHelper
  include Log
  
  def extract(dto,context)
    with_connection(@props) do
      int_words = IntWord.find(:all)
      log "Loaded #{int_words.size} interesting words."
      context[:int_words] = int_words 
    end
  end
  
end

# This block sets the +scantime+ for the current DTO
class Timestamper < ETL
  def transform(dto,context)
    dto.scantime = Time.now
  end
end
