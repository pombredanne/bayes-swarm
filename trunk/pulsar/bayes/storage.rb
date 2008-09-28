# = Bayes : PageStore extension
# Extends the FileSaver to provide additional information in the +META+ file
# pertaining to the +Page+ the stored entry belongs to (such as id, kind and
# language code)
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.

module Pulsar

  #--
  # enriches the filesaver to keep track of additional info about the current page
  #++
  module Storage
    module FileSaver
      
      # Define the Page which is currently being processed
      def page=(page)
        @page = page
      end
      
      def get_meta
        digest = Digest::MD5.hexdigest(@store_url)
        line = "#{digest} #{@store_url}"
        if @page
          line += " #{@page.id} #{@page.kind_name} #{@page.language_name}"
        end
        return line
      end            
      
    end
  end
  
  #--
  # enrich extractors
  #++
  
  class HttpMechanizeExtractor
    include Pulsar::Storage::FileSaver
  end
  
  class HttpExtractor
    include Pulsar::Storage::FileSaver
  end

  class FileExtractor
    include Pulsar::Storage::FileSaver    
  end

  class RssExtractor
    include Pulsar::Storage::FileSaver    
  end  
end

