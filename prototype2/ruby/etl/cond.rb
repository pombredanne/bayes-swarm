# = Conditional ETL blocks
# This file is part of the ETL package.
# This file contains ETL blocks that apply conditional rules on the ETL processing sequence.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'etl/std'

# Performs conditional execution of the blocks which constitute the chain. By default, this class behaves
# exactly as ChainETL. Subclasses can override the <tt>run?</tt> method to define execute conditions for each
# block in the chain.
class ConditionETL < ChainETL
  
  def b_send(block,ctx) #:nodoc:
    super(block,ctx) if run?(block, ctx[:dto],ctx)
  end
  
  # Defines whether the block passed as parameter has to execute or not. 
  def run?(block, dto, context)
    true
  end
  
end