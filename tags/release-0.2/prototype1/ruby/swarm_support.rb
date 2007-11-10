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

def swarm_extract(page, notidy=true, interesting_stems=nil)
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

def count_stems(stems, int_stems)
  stem_count = Hash.new
  stems.each do |stem|
    stem_count[stem] ||= 0
    stem_count[stem] += 1
  end
  
  res = Array.new
  stem_count.each do |s,c|
    # check if it is among interesting stems
    # only if int_stems is provided
    if int_stems == nil
      res << Stem.new(s, c, nil) unless s.length <= 2 || s =~ /\d+/
    else
      if (int_stems.has_key?(s))
        res << Stem.new(s, c, int_stems[s])
      end
    end
  end

  sorted_res = res.sort_by { |sc| sc.count }.reverse
end
