#!/usr/bin/ruby

require 'stopstem_helpers'

iws = Intword.find(:all, :conditions => {:language_id => 2600})
#roots = {}

puts "id, name, is_stop, is_root, root, word count"
iws.each do |iw|
  iwroot = root(iw.name)
  iwcount = Word.count(:all, :conditions=>{:intword_id=>iw.id})
   
  puts "#{iw.id}, #{iw.name}, #{is_stop_word?(iw.name)}, #{iwroot==iw.name}, #{iwroot}, #{iwcount}"
    
#      if roots.has_key?(iwroot)
#        roots[iwroot] += iwcount
#      else
#        roots[iwroot] = iwcount
#      end

end

#puts "root, word count"
#roots.each_pair do |r, c|
#  puts "#{r}, #{c}"
#end
