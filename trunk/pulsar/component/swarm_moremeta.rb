# = Bayes : Swarm-MoreMeta
# MoreMeta is just a quick utility script that updates the META informations stored
# in the pagestore, to enrich them with additional info (as the page_id, kind, language and
# other infos).
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'fileutils'

require 'util/log'
require 'util/lister'
require 'util/ar'

require 'bayes/ar'
require 'bayes/storage'

include Pulsar::Log
include Pulsar::AR

directory = get_opt("-d", ".")
if !File.directory?(directory)
  warn_log "#{directory} is not a valid folder."
  exit(1)
end
log "Parsing #{directory} for META files to be updated..."


# A support class to re-use FileSaver logic in creating META files.
class Meta
  include Pulsar::Storage::FileSaver
  
  def initialize(store_url)
    @store_url = store_url
  end
end

with_connection do
  
  # Extract all the META files
  lister = Pulsar::Storage::Lister.new(directory, /META$/)
  lister.extract.each do |metafile|
    
    # Create a META.old backup copy
    FileUtils.cp(metafile, metafile + ".old")
    out = ""
    
    # Open the META file and check if it has migrated yet.
    File.open(metafile + ".old", "r") do |f|
      f.each_line do |l|
        unless l.split(" ").length > 2 
          # META file still uses the old format.
          url = l.split(" ")[1]
          m = Meta.new(url)
        
          # Load page informations and migrate the META
          p = Page.find_by_url(url)
          if p
            m.page = p
          else
            warn_log "Page not found for #{url} in #{metafile}"
          end
          out << m.get_meta + "\n"
        end
      end
    end
    
    # Save the new META
    File.open(metafile, "w") { |f| f << out }
    verbose_log "Updated #{metafile} with enriched info"
  end
end