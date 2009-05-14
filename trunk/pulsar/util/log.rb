# = Utilities : Logging
# General purpose utilities related to logging
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v22 License.

module Pulsar
  
  # A module that can be included in classes to enrich them with logging methods
  module Log
  
    # Prints a message on the standard output. The message is enriched
    # with infos about the originating class and object id.
    def log(message)
      puts "#{self.class.name}(#{object_id}):: " + message.to_s
    end
  
    # Prints a message on the standard output if verbose mode is enabled. The message is enriched
    # with infos about the originating class and object id.
    def verbose_log(message)
      puts "#{self.class.name}(#{object_id}):: " + message.to_s if $-v
    end
    
    def warn_log(message)
      log "(WARN) #{message}"
    end
    
    def dry_log(message)
      log "(DRYRUN) #{message}" if Pulsar::Runner.dryRun?
    end
  
    # Returns whether verbose mode is enabled
    def verbose?
      $-v
    end
  end
end