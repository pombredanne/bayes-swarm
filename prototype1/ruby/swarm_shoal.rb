#!/usr/bin/env ruby

require 'swarm_support'

notidy = true
pages = get_pages()

for page in pages
    interesting_stems = get_interesting_stems(page.language)
    counted_stems = swarm_extract(page, notidy, interesting_stems)
    update_page_last_scantime(page, Time.now())
    if ( counted_stems != nil )    
        insert_stems_into_db(counted_stems, page.id)
    end
end
