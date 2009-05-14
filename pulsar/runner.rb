# = Pulsar Runner
# This is responsible for kickstarting all the
# scripts and execution steps. It is invoked from the command line
# with this syntax :
#
#   ruby runner.rb -c configuration_file.yml -f component
#
# such as:
#
#   ruby runner.rb -c swarm_shoal_options.yml -f test/noop
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v2.
#
require 'rubygems'

# Ruby 1.8.7 requires a version of hpricot >= 0.6.164. As such version
# is the last one to be hosted on rubyforge, we have to load the newer
# version from github. This explicit gem require ensures that the github
# version is loaded even if older ones are present in the local gem repository.
gem 'why-hpricot'

require 'yaml'
require 'util/log'

# The Pulsar module collects within itself the whole prototype 3 code.
module Pulsar
  
  # The Runner is the entry point for execution. 
  # It is responsible for loading configuration
  # options and firing execution of user defined scripts (or _components_ ).
  class Runner
    include Pulsar::Log
    
    # Creates a new instance of the class, using +config_file+ as the 
    # source of configuration options
    def initialize(config_file)
      verbose_log "Loading options..."
      @config_file = config_file
      @@opts = YAML.load(File.open(config_file))
      verbose_log "Options loaded from #{@config_file}"
    end

    # Executes the script +script_file+ by +require+ -ing it. 
    # The script should be created in such a way to start executing when 
    # required, pretty much like when launched from the
    # command line
    def go(script_file)
      log "Will execute #{script_file}.rb"
      log "Will execute a dryRun" if Runner.dryRun?
      start_time = Time.now
      require "#{script_file}"
      fin_time = Time.now
      log "Elapsed #{fin_time - start_time} seconds."
    end
    
    # Returns the options loaded from the config file. This method is 
    # created for general consumption from everywhere in the code.
    def Runner.opts
      @@opts
    end
    
    # Defines whether we are running in dryRun mode. In such mode, no data
    # should ever be written to the database.
    #
    # Each component is responsible for checking this flag and behaving properly
    def Runner.dryRun?
      flag?("--dryRun")
    end
    
  end
end

# Retrieves an options from the command line arguments.
# A option is specified as "--key value"
def get_opt(opt, default=nil)
  opt_value = $*[$*.index(opt) + 1] if $*.index(opt) && $*.index(opt) < $*.length-1
  opt_value || default
end

# Retrieves a flag from the command line arguments.
# A flag is specified as "--flag"
def flag?(flag)
  !$*.index(flag).nil?
end

if __FILE__ == $0
  config_file = get_opt("-c", "swarm_shoal_options.yml")
  script_file = get_opt("-f", "test/noop")
  
  p = Pulsar::Runner.new(config_file)
  p.go(script_file)
end