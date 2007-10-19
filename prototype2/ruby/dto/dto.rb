# = Data Transfer Objects
# This file is part of the ETL package
#
# == Description
# Data Transfer Objects (DTOs) are used to transfer values and application state
# between different ETL steps. They can be serialized and deserialized, to allow 
# ETL partitioning and suspend/resume
#
# == Serialization
# The +json+ format is used to perform serialization and deserialization. This
# open format makes easy to write ETL blocks in languages other than ruby: multiple
# json libraries exist for various programming languages. 
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
#
require 'json'

class Time #:nodoc:
  # need to open up the Time class to perform a proper JSON conversion
  
  def to_json(*a)
    {
      'json_class' => self.class.name ,
      'time' => [ to_s ]
    }.to_json(*a)
  end
    
  def self.json_create(o)
    t = Time.parse(*o['time'])
  end
end

