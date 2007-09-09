require 'etl/std'

class TestETL < ETL
  def extract(dto, context)
    dto.source = "http://news.google.com"
    dto.url = "http://news.google.com/news"
    dto.scantime = Time.at(0)
    dto.words = Array.new
    (1..5).each { |i| dto.words << WordDTO.new("word#{i}", "title", i) }
  end
end