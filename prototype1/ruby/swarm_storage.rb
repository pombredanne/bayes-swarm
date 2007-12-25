# Copyright 2007 Associazione Bayesfor. 
# Created by Riccardo Govoni (riccardo.govoni@bayesfor.eu)
require 'digest/md5'
require 'tmpdir'
require 'pathname'

# A module which contains storage-related utils
module Storage
  
  # A mixin for extractors that need file-saving capabilities
  module FileSaver
  
    # Canary method to verify if a class has mixed in FileSaver
    def is_filesaver?
      true
    end
  
    # Define the base folder where contents will be stored
    def base_folder=(b)
      @store_base = b
    end
    
    # Define the URL which is currently being processed
    def url=(u)
      @store_url = u
    end
    
    # Define the scantime which is currently being processed
    def scantime=(s)
      @store_scantime = s
    end
    
    # Returns the folder where the current contents will be stored
    def store_folder
      folder = Pathname.new(@store_base || Dir.tmpdir) 
      folder = folder.join(@store_scantime.year.to_s).join(@store_scantime.month.to_s).join(@store_scantime.day.to_s) unless @store_scantime.nil?      
      return folder.join(Digest::MD5.hexdigest(@store_url))
    end    
      
    # Save the current contents into the path returned by store_folder . 
    # Creates the folders if necessary.
    def persist(content)
      folder = Pathname.new(@store_base || Dir.tmpdir) 
      folder = folder.join(@store_scantime.year.to_s).join(@store_scantime.month.to_s).join(@store_scantime.day.to_s) unless @store_scantime.nil?
    
      begin
        url_folder = folder.join(Digest::MD5.hexdigest(@store_url))
        
        create_if_missing(url_folder)

        write_contents(url_folder.join("contents.html"),content)

        write_meta(folder.join("META"),@store_url)
      rescue SystemCallError => sce
        puts "WARNING: Unable to persist url #{url} due to error #{sce}"
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
      puts "Writing contents to #{file}"
      file.open("w") { |f| f.puts(content) }
    end
    private :write_contents
  
    def write_meta(file,url)
      puts "Writing META to #{file}"      
      digest = Digest::MD5.hexdigest(url)
      file.open("a") { |f| f.puts "#{digest} #{url}"}
    end
    private :write_meta
    
  end
end