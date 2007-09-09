# = MySQL ETL blocks
# This file contains ETL blocks that can be used to interoperate with the MySQL database, mainly
# during the *load* phase of ETL processes.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
require 'mysql'
require 'etl/std'

# This class loads DTO objects into a MySQL database. It can be used within an ETL process only during
# the *load* phase. The class operates in insert_update mode, creating resources (pages, sources, words) 
# whenever needed.
#
# Database configuration must be defined within the ETL properties. The following keys are recognized:
# * host: the hostname where the database is
# * user: the username to use for the connection
# * pass: the password to use for the connection
# * db: the database to connect to
#
# An additional property is supported: +strategy+ . This property is optional. If present, it must define
# the name of a class which will provide the word load strategy. A strategy collects the logic to properly
# analyze a WordDTO and translate it into the proper database operations. The class must implement the method
# <tt>insert(source_id,page_id,scantime,word)</tt> . 
#
# The default strategy is SimpleWordStrategy .
class MysqlLoader < ETL
  
  # loads the dto passed as parameter into a MySQL database
  def load(dto,context)
    print_warnings(dto)
    begin
      open_connection
      
      with_source(dto) do |source_id|
        with_page(dto,source_id) do |page_id|
          insert_words(source_id,page_id,dto)
        end
      end
      
    rescue Mysql::Error => me
      puts "Mysql Error: #{me}"
      raise me
    rescue Exception => e
      puts "Generic Error: #{e}"
      raise e
    ensure
      close_connection
    end
  end
  
  def print_warnings(dto) #:nodoc:
    puts "Current etl version ignores DTO tags" unless dto.tags.nil?
    words_have_tags = false
    if dto.words
      dto.words.each { |w| words_have_tags = true && break unless w.tags.nil?}
    end
    puts "Current etl version ignores Word tags" if words_have_tags
  end
  private :print_warnings
  
  # Insert all the words contained in the +dto+ into the database.
  def insert_words(source_id,page_id,dto)
    strategy = get_strategy
    if dto.words
      dto.words.each { |w| insert_word(strategy,source_id,page_id,dto.scantime,w) }
    end
  end
  
  # Inserts a single WordDTO into the database, using the provided +strategy+
  def insert_word(strategy,source_id,page_id,scantime,word)
    puts "Inserting #{word.word} for source #{source_id} and page #{page_id}" if $-v
    strategy.insert(source_id,page_id,scantime,word)
  end
  
  # Returns the strategy that will be used to insert words into the database.
  def get_strategy
    if strategy_class = @props["strategy"]
      puts "Adopting custom word strategy: #{strategy_class}" if $-v
      strategy = eval("#{strategy_class}.new")
    else
      strategy = SimpleWordStrategy.new
    end
    strategy.conn = @conn # pass the connection to the strategy
    return strategy
  end
  
  # Invokes the block passed as parameter within the context of the source defined in the dto.
  # The source is created if yet missing from the database
  def with_source(dto) 
    source_id = get_source_id(dto)
    puts "Source_id is #{source_id}" if $-v
    yield source_id
  end
  
  # Returns the id of the source defined in the dto. The source is created and a new id is assigned to it if needed.
  def get_source_id(dto)
    begin
      stmt = @conn.prepare("SELECT id FROM sources WHERE name=?")
      stmt.execute(dto.source)
      if stmt.num_rows > 0
        id = stmt.fetch[0]
      else
        stmt.close # close the previous statement
        stmt = @conn.prepare("INSERT INTO sources (name) VALUES (?)")
        stmt.execute(dto.source)
        id = stmt.insert_id
      end   
      return id   
    ensure
      stmt.close if stmt
    end
  end
  
  # Invokes the block passed as parameter within the context of the page defined in the dto.
  # The page is created if yet missing from the database  
  def with_page(dto,source_id) 
    page_id = get_page_id(dto,source_id)
    puts "Page_id is #{page_id}" if $-v
    yield page_id
  end
  
  # Returns the id of the page defined in the dto. The page is created and a new id is assigned to it if needed.  
  def get_page_id(dto,source_id)
    begin
      stmt = @conn.prepare("SELECT id FROM pages WHERE url=? AND source_id=?")
      stmt.execute(dto.url, source_id)
      if stmt.num_rows > 0
        id = stmt.fetch[0]
      else
        stmt.close # close the previous statement
        stmt = @conn.prepare("INSERT INTO pages (url,source_id) VALUES (?,?)")
        stmt.execute(dto.url,source_id)
        id = stmt.insert_id
      end      
      return id
    ensure
      stmt.close if stmt
    end
  end
  
  # Opens a connection to the database
  def open_connection
    @conn = Mysql.real_connect(@props["host"],@props["user"],@props["pass"],@props["db"])
  end
  private :open_connection
  
  # Closes the database connection
  def close_connection
    @conn.close if @conn
  end
  private :close_connection
end

# This class defines the default word strategy adopted when inserting a word into the database
# 
# A strategy collects the logic to properly analyze a WordDTO and translate it into 
# the proper database operations. Strategy instances are associated to MysqlETL blocks via their
# configuration properties.
class SimpleWordStrategy
  
  # The database connection
  attr_accessor :conn
  
  # Inserts a WordDTO into the database. This strategy uses the +position+ attribute of the WordDTO to 
  # define the database column to update. Supported positions are : *global* ,*title* . 
  # Whenever an invalid position is encountered, the word is inserted anyway (with empty counters) and a
  # warning message is issued to the user.
  def insert(source_id,page_id,scantime,word)
    @page_id , @scantime , @word = page_id, scantime, word

    insert_if_needed
    
    case word.position
    when "global"
      update "count"
    when "title"
      update "titlecount"
    else
      puts "Unrecognized word position #{word.position} for word #{word.word} and page #{page_id}"
    end
  end
  
  def update(what) #:nodoc:
    begin
      stmt = @conn.prepare("UPDATE words SET #{what} = ? WHERE name = ? AND page_id = ? AND scantime = ?")
      stmt.execute(@word.count,@word.word, @page_id, @scantime)
    ensure
      stmt.close if stmt
    end
  end
  private :update
  
  def insert_if_needed #:nodoc:
    begin
      stmt = @conn.prepare("SELECT name FROM words WHERE name=? AND page_id=? AND scantime = ?")
      stmt.execute(@word.word, @page_id, @scantime)
      if stmt.num_rows == 0
        stmt.close # close the previous statement
        stmt = @conn.prepare("INSERT INTO words (name,page_id,scantime) VALUES (?,?,?)")
        stmt.execute(@word.word,@page_id,@scantime)
      end      
    ensure
      stmt.close if stmt
    end 
  end
  private :insert_if_needed
end