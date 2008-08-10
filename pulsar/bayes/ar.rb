# = Bayes : ActiveRecord bindings
# Contains the ActiveRecord declaration of the bayes-swarm model.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'active_record'

class Intword < ActiveRecord::Base
  belongs_to :language
  
  def self.get_intwords_hash(language_id)
    # gets the list of interesting stems from db togher with their id
    # and returns a name=>id hash
    iws = find(:all, :conditions => {:language_id=>language_id})
    
    res = Hash.new
    iws.each do |iw|
      id = iw.id
      name = iw.name
      res[name] = id
    end
    res
  end
end

class Kind < ActiveRecord::Base
end

class Language < ActiveRecord::Base
  set_table_name "globalize_languages"
  
  def code; iso_639_1 end
end

class Page < ActiveRecord::Base
  belongs_to :source
  belongs_to :kind
  belongs_to :language
  
  def language_name
    language.code.intern
  end
  def kind_name
    kind.kind.intern
  end
end

class Source < ActiveRecord::Base
  has_many :pages
end

class Word < ActiveRecord::Base
  belongs_to :intword
end

#--
# TODO(battlehorse): should this method belong to the IntWord class?
#++
def get_interesting_stems(language_id)
  # gets the list of interesting stems from db togher with their id
  # and returns a name=>id hash
  iws = Intword.find(:all, :conditions => {:language_id=>language_id})
  
  res = Hash.new
  iws.each do |iw|
    id = iw.id
    name = iw.name
    res[name] = id
  end

  res
end
