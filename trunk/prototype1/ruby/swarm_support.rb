class StemCount
  attr_accessor :stem , :count
  
  def initialize(stem, count)
    @stem = stem
    @count = count
  end
end

def popular_stems(stems, max_num=10)
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
  if res.length > max_num
    res[0..max_num-1]
  else
    res
  end
end
