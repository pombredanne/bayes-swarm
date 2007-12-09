#!/usr/bin/env ruby

require 'swarm_support'
require 'swarm_ar_support'

notidy = true
pages = Page.find(:all)

for page in pages
  begin
    interesting_stems = Intword.get_intwords_hash(page.language_id)
    counted_intstems, pop_stems = swarm_extract(page, notidy, interesting_stems, 5)
    Page.update(page.id, {:last_scantime => Time.now()})
    
    pop_stems.each do |stem|
      temp = Intword.create(:name=>stem.stem,
                            :language_id=>page.language_id)
      stem.id = temp.id
    end    
    
    total_stems = counted_intstems + pop_stems    
    if ( total_stems != nil )    
      total_stems.each do |stem|
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
