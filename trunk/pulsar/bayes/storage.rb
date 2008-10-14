# = Bayes : PageStore extension
# Extends the default PageStore to provide additional information in the +META+ file
# pertaining to the +Page+ the stored entry belongs to (such as id, kind and
# language code).
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'util/storage'

module Pulsar
  
  # Extends the PageStore to enrich the amount of informations
  # stored in the META file, including some data specific to the bayes-swarm
  # database.
  class BayesPageStore < Pulsar::PageStore
    
    # Define the Page which is currently being processed
    attr_accessor :page
         
    def get_meta
      return super + (@page ? " #{@page.id} #{@page.kind_name} #{@page.language_name}" : "" )
    end
    
  end
  
end
