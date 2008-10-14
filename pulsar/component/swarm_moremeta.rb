# = Bayes : Swarm-MoreMeta
# MoreMeta is just a quick utility script that updates the META informations stored
# in the pagestore, to enrich them with additional info (as the page_id, kind, language and
# other infos).
#
# To be executed it requires a "-d" parameter to specify the directory that contains the META files.
# It also requires access to the database to merge existing Page informations.
# For example:
#   ruby runner.rb -c swarm_shoal_options.yml -f component/swarm_moremeta -d /path/to/pagestore
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

# Some old entries in the META file ended up having spurious newline
# between the md5 hash and the url. This flag is used to fix the problem.
newlinebug = false

with_connection do
  
  # Extract all the META files
  lister = Pulsar::Lister.new(directory, /META$/)
  lister.extract.each do |metafile|
    
    # Create a META.old backup copy
    FileUtils.cp(metafile, metafile + ".old")
    out = ""
    
    # Open the META file and check if it has migrated yet.
    File.open(metafile + ".old", "r") do |f|
      f.each_line do |l|
        unless l.split(" ").length > 2 
          # META file still uses the old format.
          m = Pulsar::BayesPageStore.new
          m.url = l.split(" ")[newlinebug ? 0 : 1]
          
          if m.url.nil?
            newlinebug = true
            warn_log "No url found for an entry in #{metafile}. Is this the newline bug?" if m.url.nil?
            next
          end
          
          newlinebug = false
        
          # Load page informations and migrate the META
          p = Page.find_by_url(m.url)
          if p
            m.page = p
          else
            warn_log "Page not found for #{m.url} in #{metafile}"
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