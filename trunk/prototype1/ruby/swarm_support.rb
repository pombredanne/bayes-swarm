require "mysql"

class StemCount
  attr_accessor :stem , :count

  def initialize(stem, count)
    @stem = stem
    @count = count
  end
end

class StemCountId
  attr_accessor :stem , :count, :id

  def initialize(stem, count, id)
    @id = id
    @stem = stem
    @count = count
  end
end

class Page
  attr_accessor :id, :url, :language

  def initialize(id, url, language)
    @id = id
    @url = url
    @language = language
  end
end

def swarm_extract(source, sourcetype, language='eng', notidy=true, interesting_stems=nil)
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

    stems = stemmer.stem(clean_content, language)
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

def count_stems(stems, int_stems = nil)
  stem_count = Hash.new
  stems.each do |stem|
    stem_count[stem] ||= 0
    stem_count[stem] += 1
  end

  res = Array.new
  stem_count.each do |s,c|
    res << StemCount.new(s,c) unless s.length <= 2 || s =~ /\d+/
  end

  # check if it is among interesting stems
  # skip if int_stems is nil
  if int_stems != nil
    res2 = Array.new
    res.each do |stem|
      int_stems.each do |int_stem|
        if stem.stem == int_stem.stem
          res2 << StemCountId.new(stem.stem, stem.count, int_stem.id)
        end
      end
    end
  else
    res2 = res
  end

  res2 = res2.sort_by { |sc| sc.count }.reverse
  res2
end

def get_interesting_stems(language)
  dbh = Mysql.real_connect("localhost", "testuser", "test", "bayesfortest")
  query = dbh.prepare("SELECT id, name FROM int_words WHERE language = ?")
  query.execute language

  #puts "Interesting stems are:" #debug
  res2 = Array.new
  query.each do |row|
    id = row[0]
    name = row[1]
    #printf "%s, %s\n", id, name #debug
    res2 << StemCountId.new(name, 0, id)
  end
  query.close

  res2
end

def get_pages()
  dbh = Mysql.real_connect("localhost", "testuser", "test", "bayesfortest")
  #res = dbh.query("SELECT id, url, flag FROM pages")
  res = dbh.query("SELECT id, url, language FROM pages")
  #chk = dbh.prepare "UPDATE pages SET flag = 1 where id = ? "

  pages = Array.new
  while row = res.fetch_row do
    id = row[0]
    url = row[1]
    language = row[2]
    pages << Page.new(id, url, language)
#    flag = row[2]
#    if flag == "0"
#      #printf "%s, %s\n", id, url
#       pages << Page.new(id, url)
#       chk.execute id
#    end
  end

  pages
end

def insert_stems_into_db(stems, page_id)
  dbh = Mysql.real_connect("localhost", "testuser", "test", "bayesfortest")

  res = dbh.prepare "INSERT INTO words (id, page_id, scantime, count) VALUES (?, ?, ?, ?)"
  stems.each do |stem|
    res.execute stem.id, page_id, Time.now, stem.count
  end

  res.close
end
