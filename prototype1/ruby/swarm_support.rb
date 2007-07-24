require "mysql"

class StemCount
  attr_accessor :stem , :count

  def initialize(stem, count)
    @stem = stem
    @count = count
  end
end

def count_stems(stems)
  stem_count = Hash.new
  stems.each do |stem|
    stem_count[stem] ||= 0
    stem_count[stem] += 1
  end

  res = Array.new
  stem_count.each do |s,c|
    res << StemCount.new(s,c) unless s.length <= 2 || s =~ /\d+/
  end

  res = res.sort_by { |sc| sc.count }.reverse
  res
end

def match_interesting_stems(stems, interesting_stems)
  res = Array.new
  stems.each do |stem|
    interesting_stems.each do |int_stem|
      if stem.stem == int_stem
        res << stem
      end
    end
  end
  res
end

def insert_into_db(stems)
  dbh = Mysql.real_connect("localhost", "matteo", "test", "bayesfortest")
  dbh.query("DROP TABLE IF EXISTS words")
  dbh.query("CREATE TABLE words (
                                 stem char(100) NOT NULL,
                                 count int(11),
                                 scantime DATETIME NOT NULL
                                 ) ")

  res = dbh.prepare "INSERT INTO words (stem, count, scantime) VALUES (?, ?, ?)"
  stems.each do |stem|
    res.execute stem.stem, stem.count, Time.now
  end

  res.close
end
