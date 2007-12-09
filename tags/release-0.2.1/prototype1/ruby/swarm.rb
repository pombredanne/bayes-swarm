#!/usr/bin/env ruby

require 'time'

# Option parsing
require 'optparse'
require 'ostruct'

# bayes-swarm specific
require 'swarm_support'

class Page
  attr_accessor :id, :url, :language_name, :kind_name, :last_scantime

  def initialize(id, url, language_name, kind_name, last_scantime)
    @id = id
    @url = url
    @language_name = language_name
    @kind_name = kind_name
    @last_scantime = last_scantime
  end
end

if __FILE__ == $0
    options = OpenStruct.new
    options.sourcetype = :url
    options.verbose = false

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: example.rb [options] FILE
Usage: example.rb [options] URL"

      opts.on("-s", "--sourcetype SOURCETYPE", [:url, :file, :rss], "Type of source to be extracted {url|rss|file}.") do |s|
        options.sourcetype = s
      end
      opts.on("-l", "--language LANGUAGE", [:en, :it], "Language of the source") do |l|
        options.language = l
      end      
      opts.on("--no-tidy") do |s|
        options.notidy = true
      end
      opts.on("-v", "--verbose", "Display verbose output.") do |v|
        options.verbose = v
      end
      opts.on_tail("-h", "--help", "Show this usage statement.") do |h|
        puts opts
      end
    end

    begin
      opts.parse!(ARGV)
    rescue Exception => e
      puts e, "", opts
      exit
    end

    if ARGV[0] != nil
        source = ARGV[0]

        page = Page.new(nil, source, options.language, options.sourcetype, Time.now - (60*60*24))

        stems = swarm_extract(page, options.notidy)
    else
      puts "Error: no source specified", "Example: ./swarm.rb --no-tidy http://news.google.com", "", opts
      exit
    end
end
