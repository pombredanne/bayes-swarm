#!/usr/bin/env ruby

# == Synopsis
# Generates series of x-y values.Generated numbers respect what follows:
# * x is an integer number always starting from 1 and incrementing of 1 for every generated value
# * y is a real number
#
# The y value is generated by composing the following steps:
# * a user-specified function is applied on x
# * a guassian distortion is applied on the result y=f(x)
# * a normalization or shift within a user-specified range is applied.
#
# == Usage
#   ruby generate.rb [ -h | --help] [options]
#
# The available options are:
#   -f function     : the generator function to use
#   -n num          : the number of elements to generate (starting from 1)
#   -s sigma        : the sigma to apply for gaussian distortion (0 for no distortion)
#   -p psigma      : the percent-sigma to apply for gaussian distortion (0 for no distortion)
#   -r range        : normalization range for y values, inclusive (es.: 0:5). Use only one bound to specify translations
# 
# if -s and -ps sigma are missing, a -ps 0.1 is considered.
# 
# == Example
#   ./generate.rb -f smooth_sin -n 1000 -p 0.2 -r 0:5
#   ./generate.rb -f linear -n 100 -s 0.2 -r 5:
# 
# To provide additional generators, edit stats/functions.rb
#  
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the GNU General Public License v2.
#
require 'statistics2'
require 'optparse'
require 'rdoc/usage'
require 'common'

alias function lambda
require 'statf/functions'

#
# This class wraps the functionalities described for generate.rb, so that it can be used
# as a library for another ruby program
#
class Generator
  include Common
   
  def parse_options(params) 
    options = set_options_defaults
  
    # command line parsing
    opts = OptionParser.new
    opts.on("-h", "--help") { RDoc::usage }
    opts.on("-f","--function FUNCTION") { |fun| options[:function] = fun }
    opts.on("-n [NUMBER]", Integer) { |n| options[:number] = n unless n.nil? }
    opts.on("-s [SIGMA]", Float) { |s| options[:sigma] = s unless s.nil? }
    opts.on("-p [PSIGMA]", Float) { |p| options[:psigma] = p unless p.nil? }
    opts.on("-r [RANGE]") { |r| options[:range_lower] , options[:range_upper] = r.split(":").collect{ |i| i == '' ? nil : i.to_i } unless r.nil?}

    begin
      opts.parse(params)
    rescue Exception => e
      puts "#{e}. Use --help to get some help."
      return nil
    end
    
    if options[:function].nil?
      puts "Missing function. Use --help to get some help."
      return nil
    end
    
    return options
  end
  private :parse_options
  
  def set_options_defaults(options = {})
    options[:number] ||= 100 
    options[:sigma] ||= 0
    options[:psigma] ||= 0.1
    
    return options
  end
  private :set_options_defaults
  
  def generate_raw
    f = Functions.new
    generator = eval("f.send(@options[:function])")

    y_values = Array.new
    (1..@options[:number]).each do |x|
      y = generator.call(x)
      mu = 0
      sigma = @options[:sigma].zero? ? y*@options[:psigma] : @options[:sigma]
      z_delta = Statistics2.pnormaldist(rand) # generate a gaussian noise
      y_delta = z_delta * sigma + mu
      y_values << y + y_delta
    end
    
    return y_values
  end
  private :generate_raw
  
  def locate_min_max(values)
    y_max , y_min = -10**100 , 10**100
    values.each do |y| 
      y_max = y_max > y ? y_max : y
      y_min = y_min < y ? y_min : y
    end
    
    return y_min, y_max
  end
  private :locate_min_max
  
  def apply_ranges!(y_values)
    if not @options[:range_lower].nil? or not @options[:range_upper].nil? 
      y_min, y_max = locate_min_max(y_values)

      
      if not @options[:range_lower].nil? and not @options[:range_upper].nil?
        # normalize
        y_values.collect! { |y| @options[:range_lower] + (y - y_min) * (@options[:range_upper] - @options[:range_lower]) / (y_max - y_min)}
      end

      if not @options[:range_lower].nil? 
        if @options[:range_upper].nil? 
          # translate lower bound
          y_values.collect! { |y| y - y_min + @options[:range_lower]  }
        end
      end

      if not @options[:range_upper].nil?
        if @options[:range_lower].nil?
          # translate upper bound
          y_values.collect! { |y| y - y_max + @options[:range_upper] }
        end
      end
    end
  end
  private :apply_ranges!
  
  # generates the values according to the specified options. If a non-empty map is passed
  # as parameter, the list of values will be returned by this method wrapped in a bi-dimensional
  # array of x-y values. Otherwise the values will be printed on stdout in CSV format.
  #
  # Supported options are the symbols +function+, +number+, +sigma+, +psigma+, +range_lower+, +range_upper+. 
  # Their meaning is the same as their equivalent command line switches.
  #
  # The force_embed parameters overrides automatic detection of embedded status
  def generate(options = {}, force_embed = nil)
    if options.empty?
      # load options from command line
      if ARGV.find { |f| f == "--generator" }
        @options = parse_options(split_params(ARGV,"--generator",true)) 
      else
        @options = parse_options(ARGV) 
      end
      embedded = false
    else
      # adjust only defaults
      @options = set_options_defaults(options) 
      embedded = true
    end
    
    embedded = force_embed unless force_embed.nil?
    
    # Abort on parse error
    return if @options.nil?
    
    # Generate raw values
    y_values = generate_raw()
   
    # Normalize or shift if needed
    apply_ranges!(y_values)

    # Prints the results
    if !embedded
      (1..@options[:number]).each { |x| puts "#{x}, #{y_values[x-1]}" }
    else
      res = Array.new
      (1..@options[:number]).each { |x| res << [ x , y_values[x-1] ] }
      return res
    end

  end
end

# Allow stand-alone usage of this ruby file
Generator.new.generate if $0 == __FILE__
