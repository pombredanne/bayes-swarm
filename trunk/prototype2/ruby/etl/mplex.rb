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
# which must return one or more DTOs and must be implemented by the mixing class. 
# The ETL chain will then fork for each of the returned DTOs. The execution of the chain from now on will proceed in
# parallel: every step will be executed for all the child DTOs before advancing to the next.
#
# Two forms of execution are supported, depending on the return type of <tt>mplex(dto,context)</tt>:
# if the returned type responds to methods +next+ and +adjust+ as required by LazyMultiplexDTO, a lazy
# form of execution is used, otherwise if the returned type does not respond to such methods or is an Array,
# the default form of execution is used. 
#
# When executing lazily, not all DTOs are concurrently stored in memory, but they are recalled in a linked list
# fashion.
#--
# FIXME: this may be a problem, since it will force all the results to be available at the end of the
# whole processing and not incrementally. This will also block every result if an error occurs even in 
# a single child. 
#
# A possible solution is the usage of LazyMultiplexDTO which allows for incremental processing of DTOs.
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
    if dtos.class == Array
      context[:dto] = MultiplexDTO.new(0,dtos)
    else
      if dtos.respond_to?(:next) && dtos.respond_to?(:adjust)
        context[:dto] = LazyMultiplexDTO.new(dtos)
      else
        context[:dto] = MultiplexDTO.new(0,[ dtos ])
      end
    end
  end
  alias transform extract
  alias load extract
  
  # Utility method that creates a deep copy of the DTO passed as parameter
  def deep_copy(dto)
    JSON.parse(JSON.generate(dto))
  end
  
end

