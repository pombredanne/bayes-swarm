require 'active_record'
require 'swarm_init.rb'

db_opts = $opts['database']
@db_host = db_opts[:host]
@db_user = db_opts[:user]
@db_pass = db_opts[:pass]
@db_name = db_opts[:db]

ActiveRecord::Base.establish_connection(
  :adapter  => "mysql",
  :host     => @db_host,
  :username => @db_user,
  :password => @db_pass,
  :database => @db_name
)

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
  
  def language_name()
    Page.find(self.id).language.code.intern
  end
  def kind_name()
    Page.find(self.id).kind.kind.intern
  end
end

class Source < ActiveRecord::Base
  has_many :pages
end

class Word < ActiveRecord::Base
  belongs_to :intword
end

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
