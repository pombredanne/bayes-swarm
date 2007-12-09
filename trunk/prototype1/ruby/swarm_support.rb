require 'extractor'
require 'html_tidy'
require 'stemmer'

class Stem
  attr_accessor :stem , :count, :id

  def initialize(stem, count, id)
    @id = id
    @stem = stem
    @count = count
  end
end

def swarm_extract(page, notidy=true, interesting_stems=nil, pop_stems_threshold=5)
    # Components setup
    if (page.kind_name == :url)
      extractor = HttpExtractor.new
    elsif (page.kind_name == :file)
      extractor = FileExtractor.new
    elsif (page.kind_name == :rss)
      extractor = RssExtractor.new
    elsif
      raise "unknown page kind error"
    end
    cleaner = HtmlTidy.new
    stemmer = FerretStemmer.new

    # Get the work done
    content = extractor.extract(page)
    if (notidy == true)
      clean_content = cleaner.strip_tags_and_entities(content)
    else
      clean_content = cleaner.clean(content)
    end
    # puts "CLEAN_CONTENT: #{clean_content}"

    stems = stemmer.stem(clean_content, page.language_name)
    # puts "STEMS: #{stems.inspect}"

    counted_int_stems, pop_stems = count_stems(stems, interesting_stems, pop_stems_threshold)

    i = 0
    unless counted_int_stems.empty?
      puts "Results for interesting stems:"
      counted_int_stems.each do |stem|
        puts "#{i}: #{stem.stem} (#{stem.count} occurrence(s) )"
        i += 1
      end
    else
      puts "No interesting stems found"
    end

    i = 0
    unless pop_stems.empty?
      puts "Results for popular stems (threshold=#{pop_stems_threshold}):"
      pop_stems.each do |stem|
        puts "#{i}: #{stem.stem} (#{stem.count} occurrence(s) )"
        i += 1
      end
    else
      puts "No popular stems found (threshold=#{pop_stems_threshold})"
    end
    
    return counted_int_stems, pop_stems
end

def count_stems(stems, int_stems, pop_stems_threshold)
  stem_count = Hash.new
  stems.each do |stem|
    stem_count[stem] ||= 0
    stem_count[stem] += 1
  end
  
  int_stems_found = Array.new
  # only if a list of int stems is supplied do
  if int_stems != nil
    stem_count.each do |s,c|
      # check if it is among interesting stems
      if (int_stems.has_key?(s))
        int_stems_found << Stem.new(s, c, int_stems[s])
        # delete current stem from list
        stem_count.delete(s)
      end
    end
  end
  int_stems_found = int_stems_found.sort_by { |sc| sc.count }.reverse

  # find other popular stems
  popular_stems_found = Array.new  
  stem_count.each do |s,c|
    # check if it is among interesting stems
    popular_stems_found << Stem.new(s, c, nil) unless s.length <= 2 || s =~ /\d+/
  end
  popular_stems_found = popular_stems_found.select { |sc| sc.count > pop_stems_threshold}
  popular_stems_found = popular_stems_found.sort_by { |sc| sc.count }.reverse
  
  # return int_stems and other stems
  return int_stems_found, popular_stems_found
end
