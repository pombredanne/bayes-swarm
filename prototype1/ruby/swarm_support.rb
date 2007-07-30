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


def count_stems(stems, int_stems)
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
  # FIXME: if int_stems is not passed, count_stems should return the
  # full list of stems without filtering
  res2 = Array.new
  res.each do |stem|
    int_stems.each do |int_stem|
      if stem.stem == int_stem.stem
        res2 << StemCountId.new(stem.stem, stem.count, int_stem.id)
      end
    end
  end

  res2 = res2.sort_by { |sc| sc.count }.reverse
  res2
end

def get_interesting_stems()
  dbh = Mysql.real_connect("localhost", "testuser", "test", "bayesfortest")
  res = dbh.query("SELECT id, name FROM int_words")

  puts "Interesting stems are:"
  res2 = Array.new
  while row = res.fetch_row do
    id = row[0]
    name = row[1]
    printf "%s, %s\n", id, name
    res2 << StemCountId.new(name, 0, id)
  end

  res2
end

def insert_stems_into_db(stems, page_id)
  #GRANT ALL ON bayesfortest.* TO 'testuser'@'localhost' IDENTIFIED BY 'test';
  dbh = Mysql.real_connect("localhost", "testuser", "test", "bayesfortest")

  #insert into sources (name) values ("news.google.com");
  #insert into pages (source_id, url) values (1, 'http://news.google.com');

  res = dbh.prepare "INSERT INTO words (id, page_id, scantime, count) VALUES (?, ?, ?, ?)"
  stems.each do |stem|
    res.execute stem.id, page_id, Time.now, stem.count
  end

  res.close
end
