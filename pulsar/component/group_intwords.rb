# = Bayes : Group-Intwords
# Group-Intwords is a simple tool whose purpose is to consolidate and 
# clean up the Intwords table in the database.
#
# It scans the Intwords table and looks for duplicates and words to are
# recorded in both the stemmed and not-stemmed form ( bugs in the past have 
# resulted in non-stemmed entries being inserted in the table even for languages
# that should have been stemmed ).
#
# This tool does not directly fix the database, as it may be expensive since it
# affects the words table, but it produces SQL statements that can be used to 
# do so.
# 
# To be executed it requires a "--language" parameter to specify the language
# to focus on. Use an ISO code for the language. 
# It also requires access to the database, obviously.
# For example:
#   ruby runner.rb -c swarm_shoal_options.yml \
#                  -f component/group_intwords --language en
#
# You can use these additional options:
#   --exclude-visible exclude the intwords marked as +visible+ 
#     from the computation.
#   --print-sql prints SQL statements that can be executed on the database
#     to clean it up
#
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'util/log'
require 'util/ar'
require 'util/stemmer'

require 'bayes/ar'

include Pulsar::Log
include Pulsar::AR

language = get_opt("--language")
warn_log "Focusing on language #{language} ..."

# Currently supported languages by the tool. Values represents language ids
# in the database.
language_ids = { :en => 1819, :it => 2600}
if language.nil? || language_ids[language.intern].nil?
  warn_log "You provided an invalid language (or any at all)"
  exit(1)
end

exclude_visible = flag?("--exclude-visible")
print_sql = flag?("--print-sql")
statements = []
deleted_count = 0

with_connection do
  
  log "Extracting intwords ..."
  conditions = {:language_id=> language_ids[language.intern] }
  conditions[:visible] = 0 if exclude_visible
  iws = Intword.find(:all, :conditions => conditions)
  
  stemmer = Pulsar::FerretStemmer.new
  
  log "Grouping ..."
  count_map, stem_map, id_map = {}, {}, {}
  iws.each do |intword|
    stem = stemmer.stem(intword.name, language.intern).to_s
    
    # count_map accumulates duplicate intwords
    count_map[intword.name.downcase] ||= []
    count_map[intword.name.downcase] << intword
    
    # stem_map and id_map collect words by name and id
    stem_map[intword.name.downcase] = { :iw => intword, :stem => stem }
    id_map[intword.id] = { :iw => intword, :stem => stem }
  end
  
  # Enumerate duplicates, if any
  count_map.delete_if { |k,v| v.length == 1 }.each do |name, words|
    # Find the 'good' intword. The one with lowest id, and visible
    sorted = words.sort do |w1, w2|
      w1.visible == 1 ?
        (w2.visible == 1 ? w1.id <=> w2.id : -1) :
        (w2.visible == 1 ? 1 : w1.id <=> w2.id)
    end
      
    sorted[1, sorted.length-1].each do |w|
      puts "#{w} => #{sorted[0]}"
      deleted_count += 1
      statements << "UPDATE words SET intword_id = #{sorted[0].id} " +
                    "WHERE intword_id = #{w.id} ;"
      statements << "DELETE FROM intwords WHERE id=#{w.id} ;"
      
      if sorted[0].name.downcase != sorted[0].name
        statements << "UPDATE intwords SET name = " +
                      "'#{sorted[0].name.downcase}' " +
                      "WHERE id = #{sorted[0].id} ;"
      end
    end
  end

  # Find words who are saved in the intwords both as stemmed and not-stemmed.
  # If any is found. Prepare the statements to migrate to not-stemmed over to
  # the stemmed one.
  id_map.each do |id,stemiw|
    mapped = stem_map[stemiw[:stem]]
    if !mapped.nil? && mapped[:iw].id != stemiw[:iw].id
      deleted_count += 1
      puts "#{stemiw[:iw]} => " + "#{mapped[:iw]}"
      
      statements << "UPDATE words SET intword_id = #{mapped[:iw].id} " +
                    "WHERE intword_id = #{stemiw[:iw].id} ;"
      statements << "DELETE FROM intwords WHERE id=#{stemiw[:iw].id} ;"      
    end
  end
  
  puts "A total of #{deleted_count} intwords would be cleaned up."
  
  puts "SQL Statements: " if print_sql
  statements.each { |s| puts s }  if print_sql
  
end