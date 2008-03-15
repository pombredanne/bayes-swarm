#!/usr/bin/env ruby

# == Synopsis
# Generates records for the bayes-swarm database containing statistics about words according to the bayes-swarm definition.
# This tool can be used for testing purposes to load the bayes-swarm database with fictional data
# which can be statistically analyzed and tested.
#
# For example, it can generate a simulated word count for a given word over a period of time
#
# == Usage
#   ruby persist.rb [ -h | --help] [options]
#
# The available options are:
#   -w word       : the word that will be generated. This option may also refer to a dictionary file. 
#   -t yyyymmdd   : the starting date that will be associated to the word serie
#   --page pageid : the id of the page this word belongs to
#   -e entity     : the entity the statistical data will refer to. May be one of 'count','titlecount','weight'
#   --generator   : all the options after this one will be passed to the statistical generator algorithm.
# 
# If a file is passed to the -w option, a random word is choosen from the file. The file should contain one word
# for each line. 
#
# See the help for generate.rb for further informations about generator options.
# 
# == Example
#   ./persist.rb -w newyork -t 20070801 -e count --generator -f smooth_sin -n 1000 -p 0.2 -r 0:5
#  
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
#
require 'generate'
require 'date'
require 'optparse'
require 'rdoc/usage'
require 'common'

class Persistor
  include Common
  
  def parse_options(params) 
    options = set_options_defaults
  
    # Add support for date types
    OptionParser.accept(Date, /(\d\d\d\d)(\d\d)(\d\d)/) do |d, year, mon, day| 
      Date.new(year.to_i, mon.to_i, day.to_i) 
    end 
    
    # command line parsing
    opts = OptionParser.new
    opts.on("-h", "--help") { RDoc::usage }
    opts.on("-w [WORD]") { |f| options[:word] = f unless f.nil? }
    opts.on("-t [STARTTIME]",Date) { |t| options[:starttime] = t unless t.nil? }
    opts.on("-e [ENTITY]", [ :count, :titlecount, :weight]) { |e| options[:entity] = e unless e.nil? }
    opts.on("--page [PAGE]", Integer) { |page| options[:page] = page unless page.nil? }
    
    begin
      opts.parse(params)
    rescue Exception => e
      puts "#{e}. Use --help to get some help."
      return nil
    end    
    return options
  end
  private :parse_options  
  
  def set_options_defaults(options = {})
    options[:word] ||= "en_GB.dictionary" 
    options[:starttime] ||= Date.new(Time.now.year,Time.now.month,Time.now.day)
    options[:entity] ||= :count
    options[:page] ||= 1
    
    return options    
  end
  private :set_options_defaults
 
  def load_dict
    @dict = Array.new
    if !File.exists?(@options[:word])
      @dict << @options[:word]
    else
      File.open(@options[:word]) do |f|
        f.each { |word| @dict << word.chomp.gsub(/'/,'') }
      end
    end
  end
  private :load_dict
  
  def next_word
    @dict[rand(@dict.size)]
  end
  private :next_word
  
  # generates words for the bayes-swarm database. 
  # If a non-empty map is passed as parameter, the parameters contained into the map will be used
  # instead of command line ones.
  #
  # Supported options are the symbols +word+, +starttime+, +entity+, +page+.
  # Their meaning is the same as their equivalent command line switches.
  #
  def persist(options = {})
    
    @generator = Generator.new
    
    if options.empty?
      # load options from command line
      @options = parse_options(split_params(ARGV,"--generator",false))
    else
      # adjust only defaults
      @options = set_options_defaults(options) 
    end
    
    # abort on parse error
    return if @options.nil?
    load_dict

    # pass command line options to the generator, while preserving embedded status
    data = @generator.generate({},true)
    # data = Generator.new.generate {:function => "smooth_sin" , :psigma => 0.7 , :range_lower => 0} , true
    
    scantime = @options[:starttime]
    w = next_word
    
    # FIXME : should offer the possibility to directly insert the data into mysql.
    # FIXME : should offer different kinds of statistic data conversion, not only to_i .
    data.each do |v| 
      s = "INSERT INTO words (page_id,scantime,name,#{@options[:entity]}) VALUES ("
      s += @options[:page].to_s + ","
      s += "'" + scantime.to_s + "',"
      s += "'" + w + "',"
      s += v[1].to_i.to_s # y-value of the generated data
      s += ");"
      puts s
      scantime = scantime.succ
    end unless data.nil?
  end
  
    
end

# Allow stand-alone usage of this ruby file
Persistor.new.persist if $0 == __FILE__