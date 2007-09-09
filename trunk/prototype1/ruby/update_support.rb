require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'mysql'

def load_pages(s_id, source)

   dbh = Mysql.real_connect("localhost", "testuser", "test", "bayesfortest")

   content = "" # raw content of rss feed will be loaded here
   open(source) do |s| content = s.read end
   rss = RSS::Parser.parse(content, false)

   puts "Root values"
   print "RSS title: ", rss.channel.title, "\n"
   print "RSS link: ", rss.channel.link, "\n"
   print "RSS description: ", rss.channel.description, "\n"
   print "RSS publication date: ", rss.channel.date, "\n"

   count = 0

   res = dbh.prepare "INSERT INTO pages ( source_id, url ) VALUES ( ?, ? )"
   chk = dbh.prepare "SELECT id FROM pages WHERE url = ? "
   rss.items.size.times do
       page   = rss.items[count].link
       hold   = chk.execute page
       hold   = hold.fetch
       if hold == nil 
          print page, "\n"
          count +=1
          res.execute s_id , page
       end
   end
   res.close
   chk.close
end

def get_sources()

    dbh = Mysql.real_connect("localhost", "testuser", "test", "bayesfor")
    sou = dbh.query("SELECT id, name FROM sources")
    sources = Array.new
    while row = sou.fetch_row do
        id = row[0]
        name = row[1]
        sources << Source.new(id,name)
     end
    sources
end

class Source
  attr_accessor :id , :name

  def initialize(id, name)
    @id = id
    @name = name
  end
end

