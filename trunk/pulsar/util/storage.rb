# = Utilities : File storage
# Contains code to handle saving web contents to the filesystem in
# an indexed manner, the so-called PageStore.
#
# See http://code.google.com/p/bayes-swarm/wiki/FileStorage for more info.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

require 'digest/md5'
require 'tmpdir'
require 'pathname'

require 'util/log'

module Pulsar
    
  # Represents an abstraction for the PageStore. It offers methods to load 
  # and store contents into the PageStore.
  class PageStore
    include Pulsar::Log
    
    # Checks whether the PageStore is active
    def PageStore.active?
      storage_opts = Pulsar::Runner.opts['storage'] if Pulsar::Runner
      return storage_opts && storage_opts[:filesaver] == 'active'      
    end
    
    # Returns the base folder for the PageStore. Invoke this method only
    # if the PageStore is active.
    def PageStore.baseFolder
      Pulsar::Runner.opts['storage'][:base] 
    end
    
    # Returns the date a META file refers to from its path
    def PageStore.dateFromMeta(metafile)
      if metafile =~ /(\d\d\d\d)\/(\d\d?)\/(\d\d?)\/([0-9a-f]{32})?\/?META/
        y, m, d = $1, $2, $3
        return Time.local(y, m, d)
      end
      
      return nil
    end
    
    attr_accessor :base_folder, :scantime, :url  
  
    # Returns the folder where the current contents will be stored
    def store_folder
      folder = Pathname.new(@base_folder || Dir.tmpdir) 
      folder = folder.
        join(@scantime.year.to_s).
        join(@scantime.month.to_s).
        join(@scantime.day.to_s) unless @scantime.nil?      
      return folder.join(Digest::MD5.hexdigest(@url.strip))
    end    
    
    # Save the current contents into the path returned by store_folder . 
    # Creates the folders if necessary.
    def persist(content)
      begin
        create_if_missing(store_folder)

        write_contents(store_folder.join("contents.html"),content)

        # META file is always one folder up from the URL
        # (as it contains the information to explain it)
        write_meta(store_folder.parent.join("META"),@url, @page)
      rescue SystemCallError => sce
        warn_log "Unable to persist url #{@url} due to error #{sce}"
      end
    end

    def create_if_missing(folder)
      return if folder.root?
      if !folder.exist?
        create_if_missing(folder.parent)
        folder.mkdir
      end
    end
    private :create_if_missing

    def write_contents(file,content)
      log "Writing contents to #{file}"
      file.open("w") { |f| f.puts(content) }
    end
    private :write_contents

    def write_meta(file,url,page=nil)
      log "Writing META to #{file}"      
      file.open("a") do |f| 
        f.puts get_meta
      end
    end
    private :write_meta
    
    # Returns the content to be saved in the META file. Can be
    # extended to provide addtional informations.
    def get_meta
      digest = Digest::MD5.hexdigest(@url.strip)
      "#{digest} #{@url.strip}"
    end
  end
end
