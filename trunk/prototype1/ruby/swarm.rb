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

#interesting_stems = ["china", "india", "iraq", "terror", "muslim", "islam", "bomb", "al-Qaida",
#  "bush", "you-tube", "italy"]
interesting_stems = get_interesting_stems()
puts #{interesting_stems.inspect}

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

insert_stems_into_db(counted_stems, 1)
