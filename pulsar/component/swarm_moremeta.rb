# = Bayes : Swarm-MoreMeta
# MoreMeta is just a quick utility script that updates the META 
# informations stored in the pagestore, to enrich them with additional 
# info (as the page_id, kind, language and other infos).
#
# It also fixes a bug in some META files that contain spurious newlines
# for some URL entries.
#
# To be executed it requires a "-d" parameter to specify the directory 
# that contains the META files.
# It also requires access to the database to merge existing Page informations.
# For example:
#   ruby runner.rb -c swarm_shoal_options.yml \
#                  -f component/swarm_moremeta -d /path/to/pagestore
#
# You can also use the --dryRun option to verify that everything is fine
# before actually changing the contents.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

require 'digest/md5'
require 'fileutils'

require 'util/log'
require 'util/lister'
require 'util/ar'
require 'util/rsspage'

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

# converts a META file to the new format.
#
# +file+ represents the file to be migrated. +parent_page+ may be +nil+
# or be the parent page when the META is describing entries of such page
# (as is the case for RSS items, where the parent page represents the feed)
def convert_meta(file, parent_page)
  log "Migrating file #{file}"
  
  # Use the new pageStore that creates enriched META lines.
  m = Pulsar::BayesPageStore.new
  
  # Create a backup copy of the file being migrated.
  unless Pulsar::Runner.dryRun?
    FileUtils.cp(file, file + ".old")
  end

  result = ""
  
  # Some old entries in the META file ended up having spurious newline
  # between the md5 hash and the url. This parameter is used in the
  # algorithm to fix the problem.
  newlinebug = false
  File.open(file, "r") do |f|
    md5 = ""
    f.each_line do |l|
      if l.split(" ").length > 2
        # If the line contains more than 2 tokes, it has already migrated
        result << l + "\n" 
        
      else
        md5 = l.split(" ")[0] unless newlinebug
        m.url = l.split(" ")[newlinebug ? 0 : 1]
    
        if m.url.nil?
          newlinebug = true
          warn_log "No url found for an entry in #{file}. " +
                   "Is this the newline bug?"
          next
        end
        
        # Yield to external block to get the page.
        # This is done to differentiate between 'master' pages and
        # subpages (such as RSS items)                    
        m.page = yield md5, m.url, parent_page
        if m.page
          
          # Generate the new META line
          result << m.get_meta + "\n"
          
          # Because of newlinebug, md5 hashes may have been calculated
          # including newlines and other characters. 
          # Since we are recalculating it, we may have to move the folder
          # as well.
          if newlinebug
            olddir = file.clone
            olddir[/META/] =  "/" + md5
            
            newdir = file.clone
            newdir[/META/] = "/" + Digest::MD5.hexdigest(m.url)
            
            if newdir != olddir && 
              File.exists?(olddir) && File.directory?(olddir)
              
              if Pulsar::Runner.dryRun?
                dry_log "Would have migrated dir #{olddir} to #{newdir}"
              else
                FileUtils.mv(olddir, newdir)
              end
            end
            
          end
        else
          warn_log "Page not found for #{m.url} in #{file}"
        end
        
        newlinebug = false # reset newlinebug status
      end
    end
  end
  
  # Sanity check: verify that all the migrated META entries
  # point to existing directories
  result.each_line do |l|
    dir = file.clone
    dir[/META/] =  "/" + l.split(" ")[0]
    if !File.exists?(dir) || !File.directory?(dir)
      warn_log "Migrated #{dir} does not exist!"
    end
  end

  if Pulsar::Runner.dryRun?
    dry_log "Would have written #{file} with contents "
    dry_log result
  else
    File.open(file, "w") { |f| f << result }
  end
  verbose_log "Updated #{file} with enriched info"  
end

# Scripts execution start here
with_connection do
  
  # Extract all the META files
  lister = Pulsar::Lister.new(directory, /META$/)
  lister.extract.each do |metafile|
    
    # Consider only 'master' META files, not the ones describing
    # the structure of RSS items, they need separate treatment (see below)
    if metafile !~ /[a-z0-9]{32}\/META$/
      
      convert_meta(metafile, nil) do |md5, url, parent_page|
        p = Page.find_by_url(url)
        
        # If page is of kind RSS, fix the META file relative to subitems
        if p && p.kind_name == :rss
            
          submeta = metafile.clone
          submeta[/META/] = "#{md5}/META"
          
          if File.exists?(submeta)
            convert_meta(submeta, p) do |smd5, surl, sparent_page|
              Pulsar::RssItemPage.new(surl,
                                      sparent_page.id, 
                                      sparent_page.language_name)
            end
          end
        end
        p # return the page out of the block
      end

    end
  end
end