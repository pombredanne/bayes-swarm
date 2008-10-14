# = Utilities : File lister
# Contains filesystem search utilities
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'util/log'

module Pulsar
  
  # Recursively searches for matches within a directory.
  class Lister
    
    def initialize(directory, filePattern)
      @directory = directory
      @filePattern = filePattern
    end
    
    def extract
      recursive_extract(@directory, [])
    end
    
    def recursive_extract(entry, matchingEntries)
      if File.directory?(entry)
        Dir.new(entry).
           entries.
           reject { |e| e =~ /^\./ }.
           each { |e| recursive_extract(entry + "/" + e, matchingEntries)} # recursion
      elsif File.file?(entry) && entry =~ @filePattern
        matchingEntries << entry
      end
      return matchingEntries
    end
    private :recursive_extract
    
  end
end