#!/usr/bin/env ruby

if ARGV.nil? || ARGV.size == 0
  puts "Usage: swarm.rb resource_to_be_parse [--no-tidy]"
  exit 1
end

# Requires
require 'extractor'
require 'html_tidy'
require 'stemmer'
require 'swarm_support'

# Components setup
extractor = HttpExtractor.new
#extractor = FileExtractor.new
cleaner = HtmlTidy.new
stemmer = FerretStemmer.new

# Get the work done
content = extractor.extract(ARGV[0])
if (ARGV.length == 2 && ARGV[1] == "--no-tidy")
  clean_content = cleaner.strip_tags_and_entities(content)
else
  clean_content = cleaner.clean(content)
end
# puts "CLEAN_CONTENT: #{clean_content}"

stems = stemmer.stem(clean_content)
# puts "STEMS: #{stems.inspect}"

counted_stems = count_stems(stems)
puts "No stems found" if counted_stems.empty?

interesting_stems = ["china", "india", "iraq", "terrorism", "islam", "bomb", "al-Qaida", "bush", "you-tube"]
matched_stems = match_interesting_stems(counted_stems, interesting_stems)

i = 0
unless matched_stems.empty?
  puts "Results:"
  matched_stems.each do |stem|
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

insert_into_db(matched_stems)
