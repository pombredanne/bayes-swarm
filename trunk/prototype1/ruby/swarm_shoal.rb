#!/usr/bin/env ruby

# Requires
require 'swarm'
require 'swarm_support'
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'mysql'


notidy = true
articleType = :url

pages = get_pages()
i=0
pages.length.times do
     id   = pages[i].id
     name = pages[i].name   
     lang = pages[i].lang
     load_articles(id,name,lang)
     i += 1
end

articles = get_articles()


for article in articles
    interesting_stems = get_interesting_stems(article.language)
    counted_stems = swarm_extract(article.url, articleType, article.language,notidy, interesting_stems)
    if ( counted_stems != nil )
      insert_stems_into_db(counted_stems, article.id,article.language)
    end
end
