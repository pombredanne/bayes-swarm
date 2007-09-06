### Update the db with all the news of the day 

require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'mysql'
require 'updata_support'

sources = get_sources()
i=0
sources.length.times do
     id   = sources[i].id
     name = sources[i].name   
     load_pages(id,name)
     i += 1
end



