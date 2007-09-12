require "mysql"

class Stem
  attr_accessor :stem , :count, :id

  def initialize(stem, count, id)
    @id = id
    @stem = stem
    @count = count
  end
end

class Page
  attr_accessor :id, :url, :language, :type, :last_scantime

  def initialize(id, url, language, type, last_scantime)
    @id = id
    @url = url
    @language = language
    @type = type
    @last_scantime = last_scantime
  end
end

def swarm_extract(source, sourcetype, language, notidy=true, interesting_stems=nil)
    # Components setup
    if (sourcetype == :url)
      extractor = HttpExtractor.new
    elsif (sourcetype == :file)
      extractor = FileExtractor.new
    elsif (sourcetype == :rss)
      extractor = RssExtractor.new
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

def get_interesting_stems(language)
  # gets the list of interesting stems from db togher with their id
  # and returns a name=>id hash
  dbh = Mysql.real_connect("localhost", "testuser", "test", "bayesfortest")
  query = dbh.prepare("SELECT id, name FROM int_words WHERE language = ?")
  query.execute language

  #puts "Interesting stems are:" #debug
  res = Hash.new
  query.each do |row|
    id = row[0]
    name = row[1]
    #printf "%s, %s\n", id, name #debug
    res[name] = id
  end
  query.close

  res
end

def get_pages()
  dbh = Mysql.real_connect("localhost", "testuser", "test", "bayesfortest")
  res = dbh.query("SELECT id, url, language, type, last_scantime FROM pages")

  pages = Array.new
  while row = res.fetch_row do
    id = row[0]
    url = row[1]
    language = row[2]
    type = row[3]
    last_scantime = row[4]
    pages << Page.new(id, url, language, type, last_scantime)
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
