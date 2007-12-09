#!/usr/bin/env ruby

require 'swarm_support'
require 'swarm_ar_support'

notidy = true
pages = Page.find(:all)

language_ids = Intword.count("language_id", :group=>"language_id", :distinct=>true).keys
interesting_stems = Hash.new()
language_ids.each do |l|
  interesting_stems[l] = Intword.get_intwords_hash(l)
end

for page in pages
  begin
    counted_intstems, pop_stems = swarm_extract(page, notidy, interesting_stems[page.language_id], 5)
    Page.update(page.id, {:last_scantime => Time.now()})    
    if ( counted_intstems != nil )    
      counted_intstems.each do |stem|
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
