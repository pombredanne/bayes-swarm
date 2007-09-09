# = Standard ETL blocks
# This file is part of the ETL package.
# This file contains the standard ETL blocks part of the bayes-swarm ETL package. Such blocks
# are general purpose ones, which may be usually reused in any chain, independently of its type.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'json'

# This class defines properties and methods which are shared among all ETL block implementations.
# All implementation should derive from this class. 
#
# == Defining an ETL block
# In order to be properly inserted within a chain (such as *extract* , *transform* or *load* chains) 
# implementations should define the proper callback method, and added to the chain configuration.
# The callback method MUST adhere to this signature:
#
#  def [chain_name](dto, context)
#    implementation
#  end
# 
# where <tt>[chain_name]</tt> is the name of the chain the block will belong to. For example
#
#  class MyETL < ETL
#    def extract(dto,context)
#      my_extract_impl
#    end
#  end
#
# The parameters +dto+ and +context+ respectively represent the Data Transfer Object (DTO) associated
# to this ETL run and the execution context. 
#
# Implementations may define multiple callbacks, if they can be inserted into multiple chains (for example,
# an ETL block may implement both +extract+ and +transform+ if it can work in both chains)
#
# See the documentation for ETLRunner for further info.
#
class ETL
  # The etl name. Implementations should not override this property, since the ETL name is 
  # managed via the ETL configuration file.
  attr_accessor :name
  
  # The block configuration properties. Implementations should not override this property, 
  # since the ETL properties are managed via the ETL configuration file.
  attr_accessor :props
end

# The Identity ETL, i.e., and ETL which performs nothing and just pass the ball to the next one in the
# chain. It may result useful for debugging and testing purposes.
class IdentityETL < ETL
  
  # An empty implementation of the +extract+ operation.
  def extract(dto, context)
    dto
  end
  
  # An empty implementation of the +transform+ operation.  
  def transform(dto, context)
    dto
  end
  
  # An empty implementation of the +load+ operation.  
  def load(dto, context)
    dto
  end
end

# Defines an ETL chain, i.e. a block in the ETL process which triggers the execution of a sequence
# of blocks. The chain may be configured in two different ways:
# * via the ETL configuration file using the +block+ parameters ( +block0+,+block1+ ...)
# * programmatically by direct invocations of methods on this class.
#
# This class wraps a plain array to store the chain sequence, therefore you may use standard methods to
# manipulate the chains, such as << operator.
class ChainETL < ETL
  
  # The sequence of blocks which compose this chain
  attr_reader :blocks
  
  # The phase this chain will run. May be one +extract+, +transform+ or +load+, or custom ones.
  attr_accessor :phase
  
  # Initializes a new chain. After this method call, the chain phase is still undefined.
  def initialize
    @blocks = Array.new
  end
  
  def method_missing(meth,*args, &block) #:nodoc:
    @blocks.send(meth,*args, &block)
  end
  
  # Receives the global configuration options for the whole ETL, instead of only the ones relevant for this
  # chain. 
  def global_opts=(globals)
    @opts = globals
  end
  
  # Defines the properties of this chain. The properties also contain the chain sequence definition. Refer to
  # the documentation associated to configuration files for further info on how to define a proper chain
  # sequence.
  def props=(chain_config)
    puts "Configuring chain #{@name} ..." if $-v
    @props = chain_config
    i = 0
    unless chain_config.nil?
      while token = chain_config["block#{i}"] do
        etlclass , etlname = token.split(",").reject{ |x| x == '' }
        etl = eval("#{etlclass}.new")
        etl.name = etlname || "#{@name}_#{i}_#{etlclass}"
      
        if (etl.respond_to?(:global_opts=))
          etl.global_opts = @opts
        end
        etl.props = @opts[etl.name]
        @blocks << etl
        i += 1
      end    
    end
    puts "Chain #{@name} has #{length} blocks in it" if $-v
  end
  
  # Runs this chain within the *extract* phase. This means that the +extract+ method will be invoked
  # on all the blocks composing the chain sequence.
  # Invoking this method overrides any previously set phase.
  def extract(dto,context)
    @phase = :extract
    run_chain(dto,context)
  end

  # Runs this chain within the *transform* phase. This means that the +transform+ method will be invoked
  # on all the blocks composing the chain sequence.
  # Invoking this method overrides any previously set phase.  
  def transform(dto,context)
    @phase = :transform
    run_chain(dto,context)
  end
  
  # Runs this chain within the *load* phase. This means that the +load+ method will be invoked
  # on all the blocks composing the chain sequence.
  # Invoking this method overrides any previously set phase.  
  def load(dto,context)
    @phase = :load
    run_chain(dto,context)
  end
  
  # Runs this chain. The chain phase is defined by setting the +phase+ property on this class prior to
  # invoking this method. Phase may be overriden by passing a block to this method and returning the new
  # phase to be used. 
  #
  # Chain phase defines which method will be invoked on chain blocks. Standard phases are +extract+,
  # +transform+ and +load+, but custom chains may define their own phases (such as lifecycle phases).
  def run_chain(dto,context)
    @blocks.each do |block| 
      if block_given?
        @phase = yield block
        puts "Phase is now #{@phase}" if $-v
      end
      run_block(block, dto, context)
    end
  end

  # Runs (or skips if needed) the next block of the chain and moves the chain one step forward.
  # Skipping may occur when a non-nil initial step has been defined in the configuration file.
  def run_block(block, dto, context)
    unless_step_over(block,context) do |block, ctx|
      begin
        set_step(ctx, block.name) && block.send(@phase,ctx[:dto], ctx)
      rescue Exception => e
        handle_block_exception ctx, e
      end      
    end
  end
  private :run_block 
  
  # Executes the block passed as parameter unless skipping is needed.
  def unless_step_over(block, ctx)
    if ctx[:initialstep].nil? or block.name == ctx[:initialstep]
      puts "Invoking phase #{@phase} on #{block.name}" if $-v
      ctx[:initialstep] = nil
      
      yield(block, ctx)
      
    else
      ctx[:curstep] = block.name
      puts "Skipping block #{block.name}" if $-v
    end
  end
  private :unless_step_over
  
  # sets the current step name
  def set_step(context, stepname)
    context[:curstep] = stepname
  end
  private :set_step
  
  # handles exceptions which may occur while executing a block
  def handle_block_exception(context,exc)
    puts "Error in step #{context[:curstep]} : #{exc}"
    if (context[:lastsavepointfile])
      puts "Last savepoint file #{context[:lastsavepointfile]}"
    end
    raise exc # reraise the exception to abort the whole etl
  end
  private :handle_block_exception
  
  def to_s #:nodoc:
    names = @blocks.collect { |b| b.name }.join(',')
    "#{self.class.name}: #{@name}, length #{length} [#{names}]"
  end
  
end

# This ETL block stores the current ETL status (in term of an ETLDto object) to a persistent
# store (the filesystem, in the current implementation). This allows recovery of crashed ETLs
# and analysis of ETL statuses in middle steps of operation.
#
# Savepoints can be added to an ETL process in two ways:
# * using the global savepoint configuration options in the ETL config file
# * by manually adding instances of this class into the standard ETL chains
#
class SavepointETL < ETL
  
  # Creates a new instance of the class. The +dump+ option defines if this savepoint is working
  # in dump-mode. When in dump-mode, the savepoint will not try to delete any previous savepoint
  # when storing a new one, so that the whole savepoint history is preserved at the end of the ETL
  # execution.
  def initialize(dump=false)
    @@savepoint_counter ||= 0
    @name = "savepoint#{@@savepoint_counter}"
    @counter = @@savepoint_counter
    @@savepoint_counter += 1
    @dump = dump
  end
  
  # Stores the current ETL status (an ETLDto object) to the persisten store. Due to the nature of DTOs, the file
  # contains data in the JSON format.
  def extract(dto, context)
    save(dto,context)
  end
  
  # Stores the current ETL status (an ETLDto object) to the persisten store. Due to the nature of DTOs, the file
  # contains data in the JSON format.
  def transform(dto, context)
    save(dto,context)
  end
  
  # Stores the current ETL status (an ETLDto object) to the persisten store. Due to the nature of DTOs, the file
  # contains data in the JSON format.
  def load(dto,context)
    save(dto,context)
  end
  
  # Stores the current ETL status (an ETLDto object) to the persisten store. Due to the nature of DTOs, the file
  # contains data in the JSON format.
  #
  # The key used to store the ETL status (i.e. the filename when storing to filesystem) is unique per ETL execution.
  # In case of files, the name contains the ETL process id, the current time and a progressive counter which identifies
  # this specific savepoint in the whole ETL chain.
  def save(dto,context)
    savepointfile = context[:saveloc] + '/' + Process.pid.to_s + "_" + Time.now.to_i.to_s + "_" + @counter.to_s + ".dto"
    puts "Savepoint: saving to #{savepointfile}" if $-v
    File.open(savepointfile,"w") do |f|
      f.puts JSON.generate(dto)
    end
    
    prevfile = context[:lastsavepointfile]
    File.delete(prevfile) unless prevfile.nil? || prevfile == savepointfile || @dump
    
    context[:lastsavepointfile] = savepointfile
  end
  private :save
end