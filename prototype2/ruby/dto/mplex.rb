# = Data Transfer Objects for Multiplexers
# This file is part of the ETL package
#
# == Description
# This file contains the definition of Data Transfer Objects suitable
# for multiplexed use.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
#
require 'dto/dto'

class MultiplexDTO
  
  # The pointer to the currently executing block within a multiplexed sequence.
  attr_reader :execpointer
  
  # creates a new instance of the class. +execpointer+ is the pointer the first DTO that will be
  # executed when this multiplex will be demuxed in a ChainETL . +dtos+ contains the list of DTOs which
  # compose this multiplex.
  def initialize(execpointer = 0, dtos = [])
    @dtos = dtos
    @execpointer = execpointer
  end
  
  # Declares that this DTO supports multiplexing. Anyone which needs to discriminate between DTOs
  # that support multiplexing and the ones that don't should test the presence of this method with
  # <tt>respond_to?</tt> and verify that it returns +true+ .
  def mplex?
    true
  end
  
  # Serializes this DTO into a JSON object. Refer to the JSON library
  # documentation for further info
  def to_json(*a)
    {
      'json_class' => self.class.name ,
      'data' => [ @execpointer, @dtos ]
    }.to_json(*a)
  end
  
  # Deserializes a JSON object into a proper DTO instance
  def self.json_create(o)
    d = MultiplexDTO.new(*o['data'])
  end
  
  # Increments the execution pointer, passing the +dto+ returned from the last
  # execution
  def increment_exec(dto)
    @dtos[@execpointer] = dto unless dto.nil? # replace current dto with the one returned by from block execution
    @execpointer += 1
  end
  
  # resets the execution pointer
  def reset_exec
    @execpointer = 0
  end
  
  # returns the DTO currently pointed by the execution pointer
  def cur
    if @execpointer < @dtos.size
      @dtos[@execpointer]
    else
      nil
    end
  end
  
  def to_s #:nodoc:
    "#{self.class.name} (exec #{@execpointer} out of #{@dtos.size})"
  end
  
  
end