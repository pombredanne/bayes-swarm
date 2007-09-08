require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'mysql'

dbh = Mysql.real_connect("localhost", "testuser", "test", "bayesfor")
sou = dbh.prepare "INSERT INTO sources ( name ) values ( ? )"

sources = Array.new
sources[0]="http://www.corriere.it/rss/homepage.xml"
sources[1]="http://www.lastampa.it/redazione/rss_home.xml"
sources[2]="http://www.ilgiornale.it/?RSS=S"
sources[3]="http://www.unita.it/rss/rss.asp"
sources[4]="http://www.gazzetta.it/rss/Home.xml"


sources.each do | source |
   sou.execute source
end

