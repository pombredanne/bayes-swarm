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
  
  # Creates new intwords for a given +language_id+ from a list
  # of +popular_stems+.
  def self.save_popular_stems(popular_stems, language_id)
    popular_stems.each do |stemdata|
      temp = Intword.create(:name => stemdata.stem,
                            :language_id => language_id)
      stemdata.id = temp.id    
  end
end

class Kind < ActiveRecord::Base
end

class Language < ActiveRecord::Base
  set_table_name "globalize_languages"
  
  def code
    iso_639_1 
  end
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
  def source_name
    source.name
  end
end

class Source < ActiveRecord::Base
  has_many :pages
end

class Word < ActiveRecord::Base
  belongs_to :intword
end

# Composes different list of stems into a saveable ActiveRecord Word.
# Each stem may belong to multiple page areas (body, title, header, links), but
# they concur together into defining a single word (with different counts for
# different areas). It can also calculate an overall weight for the word as a whole.
class WordComposer
  def initialize
    @words = {}
  end
  
  def add_stems_for_area(stems, area)
    stems.each do |stemdata|
      @words[stemdata.id] ||= OpenStruct.new
      @words[stemdata.id][area] = stemdata.count
    end
  end
  
  def persist(page_id, scantime)
    @words.values.each do |w|
      Word.create(:intword_id=> w.id, 
                  :page_id => page_id,
                  :scantime => scantime,
                  :count => w.count,
                  :titlecount => w.titlecount)
    end
  end
end
