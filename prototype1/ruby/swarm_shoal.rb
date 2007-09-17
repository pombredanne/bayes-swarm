#!/usr/bin/env ruby

require 'swarm_support'
require 'yaml'

def shoal_initialize(configFile="swarm_shoal_options.yml")
  opts = YAML.load(File.open(configFile))
  db_opts = opts['database']
  @db_host = db_opts[:host]
  @db_user = db_opts[:user]
  @db_pass = db_opts[:pass]
  @db_name = db_opts[:db]
end

shoal_initialize("swarm_shoal_options.yml")

notidy = true
pages = get_pages()

for page in pages
  interesting_stems = get_interesting_stems(page.language)
  begin
    counted_stems = swarm_extract(page, notidy, interesting_stems)
    update_page_last_scantime(page, Time.now())
    if ( counted_stems != nil )    
      insert_stems_into_db(counted_stems, page.id)
    end
  rescue Net::HTTPServerException
    nil
  end
end
