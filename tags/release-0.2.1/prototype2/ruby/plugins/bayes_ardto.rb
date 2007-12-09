# = Data Transfer Objects for bayes-swarm with ActiveRecord support
# This file contains DTOs specific to the bayes-swarm project, which are bound
# to ActiveRecord entities
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'dto/ardto'
require 'etl/util/ar'

# An ActiveRecord model which represents a Source
class Source < ActiveRecord::Base #:nodoc:
  
  has_many :pages
  json_include :pages
end

# An ActiveRecord model which represents a Page
class Page < ActiveRecord::Base #:nodoc:
  
  belongs_to :source
  belongs_to :language
  belongs_to :kind
  
  has_many :words
  json_include :words , :language , :kind
end

# An ActiveRecord model which represents a Word
class Word < ActiveRecord::Base #:nodoc: 
  
  belongs_to :page

end

class ExtendedWord < ActiveRecord::Base #:nodoc:
  belongs_to :language
end

class IntWord < ActiveRecord::Base #:nodoc:
  belongs_to :language
end

class Language < ActiveRecord::Base #:nodoc:
end

class Kind < ActiveRecord::Base #:nodoc:
end