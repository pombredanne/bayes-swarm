#!/usr/bin/env ruby

# Requires
require 'swarm'
require 'swarm_support'

notidy = true
sourcetype = :url

pages = get_pages()
interesting_stems = get_interesting_stems()

for page in pages
    counted_stems = swarm_extract(page.url, sourcetype, notidy, interesting_stems)
    if ( counted_stems != nil )
      insert_stems_into_db(counted_stems, page.id)
    end
end
