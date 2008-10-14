# = Bayes : Swarm-Wave
# Wave is the first component in the bayes-swarm execution chain. It is
# responsible for downloading and saving to the local filesystem all the
# web pages and rss feeds declared in the database.
#
# It is also responsible for updating the +last_scantime+ information
# on the database.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'util/log'
require 'util/ar'
require 'util/extractor'

require 'bayes/ar'
require 'bayes/storage'

include Pulsar::Log
include Pulsar::AR

# Detects whether the PageStore is active
log "File storage is active" if PageStore.active?

total_bytes = 0

with_connection do
  pages = Page.find(:all)
  log "Found #{pages.size} pages"  
  pages.each_with_index do |page, i|
    log "Elaborating page #{i+1} out of #{pages.size}"
    
    # Define the right extractor
    if (page.kind_name == :url)
      extractor = Pulsar::HttpMechanizeExtractor.new
    elsif (page.kind_name == :file)
      extractor = Pulsar::FileExtractor.new
    elsif (page.kind_name == :rss)
      extractor = Pulsar::RssExtractor.new
    elsif
      warn_log "unknown page kind #{page.kind_name}"
      next # skip the rest of the cycle
    end
    
    begin
      # Save extracted data if needed
      if PageStore.active?
        pageStore = Pulsar::BayesPageStore.new
        pageStore.base_folder = PageStore.baseFolder
        pageStore.url = page.url
        pageStore.scantime = Time.now
        pageStore.page = page
      end

      # Get the work done
      content = extractor.extract(page)
    
      if content && content.size > 0
        total_bytes += content.size
        
        # Save extracted data if needed
        if pageStore
          pageStore.persist(content)
        else
          # print out the beginning of the content for debug purposes when filesaver is not active
          log "Would have saved #{content.size} bytes : #{content[0..40]} ... "
        end
      end
    
      # Update the last scantime on the database
      Page.update(page.id, {:last_scantime => Time.now()})
    rescue
      warn_log "Unhandled expection for page #{page.url} : #{$!}"
    end
    
  end
end

log "Elaborated #{total_bytes} bytes."