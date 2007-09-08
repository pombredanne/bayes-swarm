#!/usr/bin/env ruby

# Option parsing
require 'optparse'
require 'ostruct'

# Requires
require 'extractor'
require 'html_tidy'
require 'stemmer'
require 'swarm_support'

def swarm_extract(source, sourcetype, notidy = true, interesting_stems = nil)
    # Components setup
    if (sourcetype == :url)
      extractor = HttpExtractor.new
    else
      extractor = FileExtractor.new
    end
    cleaner = HtmlTidy.new
    stemmer = FerretStemmer.new

    # Get the work done
    content = extractor.extract(source)
    if (notidy == true)
      clean_content = cleaner.strip_tags_and_entities(content)
    else
      clean_content = cleaner.clean(content)
    end
    # puts "CLEAN_CONTENT: #{clean_content}"

    stems = stemmer.stem(clean_content)
    # puts "STEMS: #{stems.inspect}"

    counted_stems = count_stems(stems, interesting_stems)
    puts "No stems found" if counted_stems.empty?

    i = 0
    unless counted_stems.empty?
      puts "Results:"
      counted_stems.each do |stem|
        puts "#{i}: #{stem.stem} (#{stem.count} occurrence(s) )"
        i += 1
      end

      # puts "Talks about ? "
      # found = false
      # counted_stems.each do |stemcount|
      #   found |= stemcount.stem =~ /terror/
      # end
      # puts "YES!" if found
      # puts "NO!" unless found
    end

end

if __FILE__ == $0
    options = OpenStruct.new
    options.sourcetype = :url
    options.verbose = false

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: example.rb [options] FILE
Usage: example.rb [options] URL"

      opts.on("-s", "--sourcetype SOURCETYPE", [:url, :file], "Type of source to be extracted {url|file}.") do |s|
        options.sourcetype = s
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

        stems = swarm_extract(source, options.sourcetype, options.notidy)
        puts stems
    else
      puts "Error: no source specified", "Example: ./swarm.rb --no-tidy http://news.google.com", "", opts
      exit
    end
end
