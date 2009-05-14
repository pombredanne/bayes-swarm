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
# Licensed under the GNU General Public License v2.

require 'util/log'
require 'util/ar'
require 'util/extractor'

require 'bayes/ar'
require 'bayes/storage'

include Pulsar::Log
include Pulsar::AR

# Utility method that creates a pageStore ready to persist
# a page to disk
def get_pagestore(base_folder, extracted_page, time)
  # Use the Bayes-specific store, that creates rich META files
  pageStore = Pulsar::BayesPageStore.new
  pageStore.base_folder = base_folder
  pageStore.url = extracted_page.page.url
  pageStore.scantime = time
  pageStore.page = extracted_page.page
  
  return pageStore
end

# Detects whether the PageStore is active and set it up
log "File storage is active" if Pulsar::PageStore.active?

total_bytes = 0

with_connection do |connection|
  pages = Page.find(:all)
  log "Found #{pages.size} pages"  
  pages.each_with_index do |page, i|
    connection.reconnect!
    log "Elaborating page #{i+1} out of #{pages.size}"
    
    # Skip pages if requested.
    unless get_opt("--page").nil?
      if get_opt("--page").to_i != page.id
        log "Skipping page with id #{page.id}"
        next
      end
    end
    
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
      # Get the work done
      extracted_page = extractor.extract(page)
      connection.reconnect!
    
      if extracted_page && extracted_page.content.size > 0
        total_bytes += extracted_page.content.size
        
        if Pulsar::PageStore.active?
          
          # Store the extracted page
          pageStore = get_pagestore(Pulsar::PageStore.baseFolder,
                                    extracted_page,
                                    Time.now())
          pageStore.persist(extracted_page.content) 
                    
          # Store subpages (such as RSS Items, if any)
          extracted_page.subpages.each do |subpage|
            
            # The subpage is store _under_ the parent page folder,
            # with no extra time information (as it is the same as the
            # parent one)
            subpageStore = get_pagestore(pageStore.store_folder,
                                         subpage,
                                         nil)
            subpageStore.persist(subpage.content)
          end
        else
          # print out the beginning of the content for debug purposes 
          # when filesaver is not active
          log "Would have saved #{extracted_page.content.size} bytes : " +
              "#{extracted_page.content[0..40]} ... "
        end
      end
    
      # Update the last scantime on the database
      if Pulsar::Runner.dryRun?
          dry_log "Would have updated last_scantime to #{Time.now()} " +
              "for page #{page.id}"
      else
        Page.update(page.id, {:last_scantime => Time.now()})
      end
    rescue
     warn_log "Unhandled expection for page #{page.url} : #{$!}"
    end
    
  end
end

log "Elaborated #{total_bytes} bytes."
