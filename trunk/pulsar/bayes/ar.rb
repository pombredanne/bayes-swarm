# = Bayes : ActiveRecord bindings
# Contains the ActiveRecord declaration of the bayes-swarm model.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

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
      name = iw.name.clone
      res[name] = id
    end
    res
  end
  
  # Creates a map of intwords whose names contains 'troublesome' characters,
  # that is, characters that I'm not yet able to push successfully over the
  # wire to Amazon SDB.
  # A cursory check over the excluded words shows that, as of June 2009, we
  # are excluding only spurious words (often with leading or trailing accents
  # that should have been removed) with a negligible total count.
  def self.get_i18n_unsafe_words_hash
    iws = find(:all, :conditions => 
      ["name not regexp '^([a-zA-Z0-9]|[[:space:]]|[[:blank:]]|-|\\'|[.,_&/])*$'"])
    res = Hash.new
    iws.each do |iw|
      res[iw.id] = iw.name.clone
    end
    res
  end
  
  # Creates new intwords for a given +language_id+ from a list
  # of +popular_stems+. Each element of the list is supposed to
  # be an instance of +StemData+ (as defined in +stemmer.rb+).
  def self.save_popular_stems(popular_stems, language_id)
    popular_stems.each do |stemdata|
      temp = Intword.create(:name => stemdata.stem,
                            :language_id => language_id)
      stemdata.id = temp.id    
    end
  end
  
  def to_s
    "#{name} (id=#{id},vis=#{visible})"
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
 
  # Saves a list of stems as a serie of Words.
  # Each stem may belong to multiple page areas (body, title, header, links...),
  # but they concur together into defining a single word (with different counts
  # for different areas).
  #
  # Saving is not guaranteed: this function expects a block whose job is to
  # evaluate if the word qualifies for saving. Usually the block would perform
  # a threshold check.
  # The block receives a +StemData+ and must return a boolean.
  #
  # The function returns a boolean that says if saving was performed (and
  # succeeded) or not.
  def Word.create_stems(page_id, scantime, stemdata)
    created = false;
    params = {
      :intword_id => stemdata.id,
      :page_id => page_id,
      :scantime => scantime,
      :count => stemdata.count
    }

    if stemdata.page_area.size > 0
      # If we are keeping track of different page areas, 
      # recalculate the total to avoid double-counting some elements
      # (such as anchors and headings within the body)
      params[:count] = stemdata.count_for(:bodycount) + 
                       stemdata.count_for(:titlecount) + 
                       stemdata.count_for(:keywordcount)
                       
      params = params.merge(stemdata.area_count)
    end
    
    over_threshold = yield stemdata
    
    if over_threshold
      if Pulsar::Runner.dryRun?
        dry_log "Would create word (#{stemdata.stem},#{stemdata.id}) " +
                "with count=#{params[:count]} and areas #{stemdata.area_count} " +
                "for page #{page_id} and time #{scantime}"
      else    
        Word.create(params)
      end
      created = true
    end
    return created
  end
end
