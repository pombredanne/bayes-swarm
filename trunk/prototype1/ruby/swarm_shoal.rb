#!/usr/bin/env ruby

# Requires
require 'swarm'
require 'swarm_support'
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'mysql'


notidy = true
sourcetype = :url

sources = get_sources()
i=0
sources.length.times do
     id   = sources[i].id
     name = sources[i].name   
     lang = sources[i].lang
     load_pages(id,name,lang)
     i += 1
end

pages = get_pages()


for page in pages
    interesting_stems = get_interesting_stems(page.language)
    counted_stems = swarm_extract(page.url, sourcetype, page.language,notidy, interesting_stems)
    if ( counted_stems != nil )
      insert_stems_into_db(counted_stems, page.id,page.language)
    end
end
