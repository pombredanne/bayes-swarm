# = Data Transfer Objects for bayes-swarm
# This file contains DTOs specific to the bayes-swarm project.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'dto/dto'

#
# An ETL DTO is the main object which is passed among etl steps. 
# Contains a full representation of the current etl process and it keeps
# track of words and sources. 
# 
# It also contains the definition of *tags*, as optional attributes that may
# be attached to words or to the whole ETL process
#
class ETLDTO
  
  attr_accessor :words, :url, :source, :scantime, :tags
  
  # Creates a new instance of this DTO. All parameters are free types
  # but in general terms, +words+ should be a list of WordDTO objects,
  # +tags+ should be an Hash , +url+ and +source+ a String, representing
  # the url currently under analysis and the hostname it belongs to, and 
  # +scantime+ a Time object representing when the scan occurred
  def initialize(url = nil, source = nil, scantime = nil,  tags = nil, words = nil)
    @url = url 
    @source = source
    @tags = tags
    @words = words
    @scantime = scantime
  end
  
  # Serializes this DTO into a JSON object. Refer to the JSON library
  # documentation for further info
  def to_json(*a)
    {
      'json_class' => self.class.name ,
      'data' => [ @url , @source , @scantime, @tags , @words ]
    }.to_json(*a)
  end
  
  # Deserializes a JSON object into a proper DTO instance
  def self.json_create(o)
    d = ETLDTO.new(*o['data'])
  end
  
  def to_s #:nodoc:
    "#{@source} => #{@url} (#{@words ? @words.size : 0} words)"
  end
end

class SourceDTO
  attr_accessor :source, :language
  
  def initialize(source = nil, language = nil)
    @source = source
    @language = language
  end
  
  def to_json(*a)
    {
      'json_class' => self.class.name ,
      'data' => [ @source , @language ]
    }.to_json(*a)
  end
  
  def self.json_create(o)
    s = SourceDTO.new(*o['data'])
  end
  
  def to_s #:nodoc:
    "#{@source}"
  end
end

class PageDTO
  attr_accessor :url, :language
  
  def initialize(url = nil, language = nil)
    @url = url
    @language = language
  end
  
  def to_json(*a)
    {
      'json_class' => self.class.name ,
      'data' => [ @url , @language ]
    }.to_json(*a)
  end
  
  def self.json_create(o)
    s = PageDTO.new(*o['data'])
  end
  
  def to_s #:nodoc:
    "#{@source}"
  end
end

# A word DTO represents a single word extract from a source during
# an ETL proces. 
class WordDTO
  attr_accessor :id, :word, :position, :count, :language, :tags
  
  # Creates a new instance of this DTO. This DTO represents a single
  # +word+ from a given source. A +word+ has two attributes: a +position+
  # which declares its position within the page ( such as title, headings, corners
  # and so on...) and a +count+ which declares the word count in that position.
  #
  # A word may have a set of optional custom *tags* .
  def initialize(id = nil, word = nil, position = nil ,count = 0,language = nil, tags = nil)
    @id = id
    @word = word
    @position = position
    @language = language
    @count = count
    @tags = tags
  end
  
  # Serializes this DTO into a JSON object. Refer to the JSON library
  # documentation for further info  
  def to_json(*a) 
    {
      'json_class' => self.class.name ,
      'data' => [ @id, @word, @position , @count, @language ,@tags]
    }.to_json(*a)
  end
  
  # Deserializes a JSON object into a proper DTO instance  
  def self.json_create(o)
    w = WordDTO.new(*o['data'])
  end
  
  def to_s #:nodoc:
    "#{@word} [id=#{@id},pos=#{@position},count=#{@count}]"
  end
end

# A language DTO represents a language that may be applied
# to sources, pages or words.
class LanguageDTO
  attr_accessor :id , :language
  
  # Creates a new instance of this DTO
  def initialize(id = nil, language = nil)
    @id = id
    @language = language
  end

  # Serializes this DTO into a JSON object. Refer to the JSON library
  # documentation for further info  
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data' => [ @id , @language ]
    }.to_json(*a)
  end
  
  # Deserializes a JSON object into a proper DTO instance  
  def self.json_create(o)
    lang = LanguageDTO.new(*o['data'])
  end
  
  def to_s #:nodoc:
    "#{@language}"
  end
end