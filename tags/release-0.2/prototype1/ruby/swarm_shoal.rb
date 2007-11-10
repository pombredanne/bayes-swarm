#!/usr/bin/env ruby

require 'swarm_support'
require 'swarm_ar_support'

notidy = true
pages = Page.find(:all)

for page in pages
  interesting_stems = get_interesting_stems(page.language_id)
  begin
    counted_stems = swarm_extract(page, notidy, interesting_stems)
    Page.update(page.id, {:last_scantime => Time.now()})    
    if ( counted_stems != nil )    
      counted_stems.each do |stem|
        Word.create(:intword_id=>stem.id, 
          :page_id=>page.id, 
          :scantime=>Time.now(), 
          :count=>stem.count)
      end
    end
  rescue
    puts "Unhandled exception: #{$!}"
  end
end
