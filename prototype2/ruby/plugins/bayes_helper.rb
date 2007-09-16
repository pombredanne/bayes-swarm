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
require 'etl/util/db'

# This block loads the list of interesting words and stores it into the context under
# the key <tt>:int_words</tt> as an array of hashes. Each hash will have the +id+ and +name+ keys
# referring to the same properties of each loaded int_word.
class IntWordInitializer < ETL
  include DatabaseHelper
  include Log
  
  def extract(dto,context)
    with_connection(@props) do
      context[:int_words] = get_int_words
    end
  end
  
  def get_int_words
    int_words = []
    @conn.query("SELECT id,name FROM int_words ") do |res| 
      while row = res.fetch_row do
        int_words << { :id => row[0] , :name => row[1]}
      end
    end
    log "Loaded #{int_words.size} interesting words."
    return int_words
    
  end
  private :get_int_words
  
end

# This block sets the +scantime+ for the current DTO
class Timestamper < ETL
  def transform(dto,context)
    dto.scantime = Time.now
  end
end
