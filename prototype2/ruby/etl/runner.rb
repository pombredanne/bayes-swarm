# = ETL Runner
# This file is part of the ETL package.
# See the documentation for ETLRunner as a starting point.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
#
require 'json'
require 'yaml'
require 'etl/util/log'
require 'dto/dto'
require 'etl/std'
require 'etl/stdload'

# The ETL Runner is responsible for running ETL processes. 
#
# == Description
# A single ETL process is composed of three *chains*: 
# * Extract: this chain is responsible for extracting the data to be analyzed and storing them locally for further processing 
# * Transform: this chain may apply transformations to the data
# * Load: this chain is responsible for loading the data in a persistent store, such as a database
# 
# Each chain is composed of *blocks* , i.e. single <b>ETL steps</b>. A block is a subclass of ETL
# and implements the relevant methods, depending on the chain it belongs to. Nothing prevents a block
# from working in different chains (see IdentityETL for example). 
# 
# == Configuration
# All the options used at runtime by the ETL Runner are declared in a configuration file. The configuration
# file uses the YAML format and is therefore human-readable and editable. 
# The configuration file stores:
# * the global options for the ETL Runner (such as savepoint configuration)
# * the enumeration of the blocks which compose the default extract,transform and load chains
# * the configuration parameters for every single block
# * the configuration of subchains, if any.
#
# What follows is a sample configuration file (etl_config.yml) :
#
#   :include: etl_config.yml
#
# == Data Recovery
# The ETL Runner supports savepoints. Savepoints are used to store execution status at a fixed point
# in time, so that in case of failure, the ETL process can restart from the last valid savepoint. 
# 
# Savepoints are enabled from the configuration file. The restart point and the data to be used when resuming
# are defined in the configuration file too.
#
# == Plugins and User Custom ETL Blocks
# In addition to standard ETL blocks, provided with the library, such as ChainETL and SavepointETL, the user may
# want to provide its own custom ETL blocks. To do so, he must collect its own ETL blocks in files stored within
# the same directory and then declare that directory as the <b>plugins folder</b>. The ETLRunner will dinamically
# load all suitable ruby files found within such directory.
#
# == Verbose execution
# ETLRunner and standard ETLs observe the hints for verbose execution. Use the <tt>-v</tt> command line
# switch or the <tt>$-v</tt> global variable to enable verbose execution.
# 
# == Sample Invocation
# A sample invocation works as follows :
#   require 'etl/runner'
#   e = ETLRunner.new('my_etl_config.yml')
#   e.run
#
# Depending on the ETL configuration and on single blocks implementations,
# while running the ETL process may produce output to +stdout+, or save intermediate
# dtos into a user-specified folder for debugging purposes. 
class ETLRunner
  include Log
  
  # Creates a new instance of the class, using +configFile+ as the source of configuration options
  def initialize(configFile="etl_config.yml")
    @applied_savepoints = false
    @config_file = configFile
    @opts = YAML.load(File.open(configFile))
    init_plugins
    init_default_chains
  end
  
  def init_plugins
    pluginsfolder = @opts[:pluginsfolder] || "./plugins"
    $: << pluginsfolder
    Dir.new(pluginsfolder).each do |filename|
      if filename =~ /([^\.]*)\.rb$/ && File.file?(pluginsfolder + "/" + filename)
        log "Loaded plugin #{$1} from #{pluginsfolder}" if require $1
      end
    end
    
  end
  
  # Initializes the root chain, which in turn defines the
  # default etl chains: *extract* , *transform*, and *load*.
  # 
  # The root chain MUST always be present in the configuration file
  def init_default_chains
    raise "Missing root chain in conf file" unless @opts["root"]
    @root_chain = ChainETL.new
    @root_chain.name = "root"
    @root_chain.global_opts = @opts
    @root_chain.props= @opts["root"]
  end
  
  # Starts the ETL process, from the first block of the first chain. 
  def run(extra_context = {})
    @context = init_context()    
    enrich_context(extra_context)
    enable_savepoints if global_opt(:savepoint)  

    begin
      @root_chain.run_chain(@context[:dto],@context) { |block| block.name.to_sym }
      clean
    rescue Exception => e
    end
  end
  
  # Initializes the shared *context*. The *context* is a shared Hash among the different etl blocks 
  # which they can use to propagate data among each other. 
  #
  # The shared context always contains at least the +:dto+ variable which points to the ETLDto which 
  # collects analysis data for the current run. 
  def init_context 
    if global_opt(:recover)
      recover_file = (global_opt(:saveloc) || File.dirname($0)) + "/" + global_opt(:recover)
      dto = JSON.load(File.new(recover_file))
      verbose_log "Recovered DTO from #{recover_file}"
    else
      dto = ETLDTO.new
    end
    @context={ :dto => dto , :initialstep =>  global_opt(:initialstep) , :argv => ARGV }
  end
  
  # Enriches the shared *context* with extra data which may provided from the outside
  # of the ETLRunner .
  def enrich_context(extra_context)
    @context.merge(extra_context) unless extra_context.nil?
  end
  
  # Enriches the standard chains with savepoint management and stores 
  # into context the folder where savepoint dumps will be stored. 
  def enable_savepoints
    @root_chain.collect! { |c| add_savepoints_to(c) } unless @applied_savepoints 
    @context[:saveloc] = global_opt(:saveloc) || File.dirname($0)
    @applied_savepoints = true
  end
  
  # Duplicates the given chain and returns a new one with savepoints interleaved between each block. 
  def add_savepoints_to(chain)
    chain.collect! { |  block| [ block , SavepointETL.new(global_opt(:savepointdump)) ] }.flatten!
    return chain
  end 
  
  # Performs cleaning operations before exiting, such as clearing savepoint data if no errors occurred.
  def clean
    File.delete(@context[:lastsavepointfile]) unless @context[:lastsavepointfile].nil? || global_opt(:savepointdump)
  end
     
  # Returns a global configuration option
  def global_opt(sym)
    @opts["globals"] && @opts["globals"][sym]
  end
  
  def to_s #:nodoc:
    "#{self.class.name}: config #{@config_file} with #{@root_chain.length} chains"
  end
  
end
