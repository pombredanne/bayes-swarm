#!/usr/bin/ruby

require 'stopstem_helpers'

iws = Intword.find(:all, :conditions => {:language_id => 2600})

puts "id, name, word count"
iws.each do |iw|
  if (is_stop_word?(iw.name))
    puts "#{iw.id}, #{iw.name}, #{Word.count(:all, :conditions=>{:intword_id=>iw.id})}"
  end
end
