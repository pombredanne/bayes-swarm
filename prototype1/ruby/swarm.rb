#!/usr/bin/env ruby

# Option parsing
require 'optparse'
require 'ostruct'

# Requires
require 'extractor'
require 'html_tidy'
require 'stemmer'
require 'swarm_support'

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
      opts.on("-l", "--language LANGUAGE", [:eng, :ita], "Language of the source") do |l|
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

        stems = swarm_extract(source, options.sourcetype, options.language, options.notidy)
    else
      puts "Error: no source specified", "Example: ./swarm.rb --no-tidy http://news.google.com", "", opts
      exit
    end
end
