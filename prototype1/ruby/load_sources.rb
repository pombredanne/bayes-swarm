require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'mysql'

dbh = Mysql.real_connect("localhost", "testuser", "test", "bayesfortest")
sou = dbh.prepare "INSERT INTO sources ( name, language ) values ( ? , ?)"
get = dbh.prepare "SELECT id FROM sources WHERE name = ? "
pag = dbh.prepare "INSERT INTO pages ( source_id, url, language ) values ( ?, ?, ? ) "



sources = Array.new
sources[0]="http://www.corriere.it/rss/homepage.xml"
sources[1]="http://www.lastampa.it/redazione/rss_home.xml"
sources[2]="http://www.ilgiornale.it/?RSS=S"
sources[3]="http://www.unita.it/rss/rss.asp"
sources[4]="http://www.gazzetta.it/rss/Home.xml"


sources.each do | source |
   sou.execute source, 'ita'
   hold=get.execute source
   hold=hold.fetch
   print hold
   pag.execute hold[0], source, "ita"
end


