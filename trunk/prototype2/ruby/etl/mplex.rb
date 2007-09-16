# = Multiplexer ETL blocks
# This file is part of the ETL package.
# This file contains the support structures to work with *multiplexed* etl blocks. A
# Multiplexer has the ability to perform its subsequent tasks a number of times, 
# varying the DTO in use from time to time, depending on a given condition.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'etl/std'
require 'dto/mplex'
require 'json'

# An ETL block that needs to fork execution of the ETL chain, varying the DTOs in use for each forked 
# segment should mix in this module. This module relies on a <tt>mplex(dto,context)</tt> method,
# which must return an array of DTOs and must be implemented by the mixing class. 
# The ETL chain will then fork for each of the returned DTOs. The execution of the chain from now on will proceed in
# parallel: every step will be executed for all the child DTOs before advancing to the next.
#--
# FIXME: this may be a problem, since it will force all the results to be available at the end of the
# whole processing and not incrementally. This will also block every result if an error occurs even in 
# a single child. 
#++
# A sample usage of this module follows :
#   class MyMultiplexETL < ETL
#     include MultiplexETL
#     def mplex(dto,context)
#       dtos = Array.new
#       ... perform multiplexing ops ...
#       return dtos
#     end
#   end
module MultiplexETL
  
  def extract(dto,context) 
    dtos = mplex(dto,context)
    context[:dto] = MultiplexDTO.new(0,dtos)
  end
  alias transform extract
  alias load extract
  
  # Utility method that creates a deep copy of the DTO passed as parameter
  def deep_copy(dto)
    JSON.parse(JSON.generate(dto))
  end
  
end

