# = Utilities : Logging
# General purpose utilities related to logging
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

module Pulsar
  
  # A module that can be included in classes to enrich them with logging methods
  module Log
  
    # Prints a message on the standard output. The message is enriched
    # with infos about the originating class and object id.
    def log(message)
      puts "#{self.class.name}(#{object_id}) #{now}:: " + message.to_s
    end
  
    # Prints a message on the standard output if verbose mode is enabled. The message is enriched
    # with infos about the originating class and object id.
    def verbose_log(message)
      puts "#{self.class.name}(#{object_id}) #{now}:: " + message.to_s if $-v
    end
    
    def warn_log(message)
      log "(WARN) #{now} #{message}"
    end
    
    def dry_log(message)
      log "(DRYRUN) #{now} #{message}" if Pulsar::Runner.dryRun?
    end
  
    # Returns whether verbose mode is enabled
    def verbose?
      $-v
    end
    
    def now
      t = Time.now
      "#{t.strftime('%Y%m%d %H:%M:%S')}.#{t.usec}"
    end
  end
end