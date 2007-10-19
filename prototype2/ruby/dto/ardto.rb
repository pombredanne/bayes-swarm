# = Data Transfer Objects and Active Record
# This file is part of the ETL package and contains support structures to map between
# DTOs and ActiveRecord.
#
# == Object-Relational Mapping and JSON
# This file enriches ActiveRecord (by mixin some code into <tt>ActiveRecord::Base</tt> )
# to allow to-and-from conversion between ActiveRecord entities and JSON objects. 
# Refer to the ActiveRecord documentation for further info.
#
# Conversion from AR to JSON allows relationship traversal via the <tt>json_include</tt> macro, as in the 
# following example:
#   class Order < ActiveRecord::Base
#     has_many :items
#     json_include :items
#   end
#   ...
#   require 'json'
#   o = Order.find(10)
#   s = JSON.generate(o)
#
# Conversion from JSON to AR tries loading the serialized entities from the database (via +find+ method, using the +id+ 
# the entity had at serialization time). If the load fails, the entity is created as new (discarding the previous id).
# This behavior has some side-effects:
# * if an entity is deleted between serialization and restore, on +save+ will be recreated with a different id,
# * if an entity changes foreign key between serialization and restore, on +save+ will be reassigned to the original parent.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
#

require_gem 'activerecord'
require 'json'

# The module to be mixed in with <tt>ActiveRecord::Base</tt> to enrich ActiveRecord with to-and-from JSON
# support
module JSONMixin
  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
  end
  
  module ClassMethods #:nodoc:
    def json_include(entities = [])
      class_eval <<-EOV
        include JSONMixin::InstanceMethods
        
        def json_included_entities() #{entities.inspect} end
      EOV
    end    
  end
  
  module InstanceMethods #:nodoc:
    def json_propagate_to_entities
      entities = json_included_entities
      entities = [ entities ] unless entities.class == Array
      res = []
      entities.each do |e|
        if respond_to?(e)
          res << send(e) # force loading of childs from database
        end
      end
      return res
    end
    
    def json_recover_entities(*data)
      entities = json_included_entities
      entities = [ entities ] unless entities.class == Array
      count = 0
      entities.each do |e|
        if respond_to?("#{e.to_s}=")  # convert symbols to string and append = for setter method
          send("#{e.to_s}=",data[count])
          count += 1
        end
      end
    end
  end
end

class ActiveRecord::Base #:nodoc:
  include JSONMixin
  
  # Converts the ActiveRecord object to a JSON string.
  def to_json(*a)    
    {
      'json_class' => self.class.name ,
       'data' => [ attributes ] ,
       'id' => id , 
       'include' => respond_to?(:json_propagate_to_entities) ? json_propagate_to_entities : []
    }.to_json(*a)

  end

  # Restores a JSON-ized object. Tries to match it back with the original entity it came from
  def self.json_create(o)
    obj , id = nil , *o["id"]
    if eval(*o['json_class'] + ".exists?(#{id})")
      obj = eval(*o['json_class'] + ".find(#{id})")
      # puts "Loaded #{obj}"
    else
      obj = eval(*o['json_class'] + ".new")
      # puts "Created #{obj}"
    end
    obj.attributes = *o['data']
    obj.json_recover_entities(*o['include']) if obj.respond_to?(:json_recover_entities)
    return obj
  end
    
end
