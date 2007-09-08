#!/usr/bin/env ruby

# Requires
require 'swarm'
require 'swarm_support'
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'mysql'
require 'update_support'

notidy = true
sourcetype = :url

sources = get_sources()
i=0
sources.length.times do
     id   = sources[i].id
     name = sources[i].name   
     load_pages(id,name)
     i += 1
end

pages = get_pages()
interesting_stems = get_interesting_stems()

for page in pages
    counted_stems = swarm_extract(page.url, sourcetype, notidy, interesting_stems)
    if ( counted_stems != nil )
      insert_stems_into_db(counted_stems, page.id)
    end
end
