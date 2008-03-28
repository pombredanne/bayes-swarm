require 'pagestore'

class PagestoreController < ApplicationController
  layout "standard" , :only => "disclaimer"
  
  def show
    intword_ids = params[:id].split("-")
    @date = Date.strptime(params[:date])
    
    @store = PageStore.new
    
    #FIXME(battlehorse): warning! this performs N+1 queries
    intword_ids.each do |iw_id|
      iw = Intword.find(iw_id)
      ws = iw.words.sum(:count,
                        :conditions => "scantime>='#{@date}' AND scantime <= '#{@date+1}'",
                        :group => "page_id"  )
                                
      ws.keys.each_with_index do |page_id,index|
        @store.add(iw,page_id,ws.values[index])
      end
    end

  end
  
  def history
    pageurl = Page.find(params[:page]).url
    date = Date.strptime(params[:date])
    
    metafile = PAGESTORE_LOCATION + "#{date.year}/#{date.month.to_i}/#{date.day.to_i}/META"
    contentsfile = nil
    if File.exists?(metafile)
      File.open(metafile) do |f|
        f.each_line do |l|
          md5, url = l.split(" ")
          contentsfile = PAGESTORE_LOCATION + "#{date.year}/#{date.month.to_i}/#{date.day.to_i}/#{md5}/contents.html" if pageurl == url.chomp
        end
      end
    end
    
    if contentsfile.nil?
      @contents = "<html><body>"
      @contents << "<p>The historical version of this webpage is no longer available online.</p>"
      @contents << "<p>If you are really interested in this page, <a href='mailto:info@bayesfor.eu'>contact us</a>, since we keep an offline historical archive</p>"
      @contents << "</body></html>"
    else
      @contents = ""
      File.open(contentsfile) do |f|
        f.each_line { |l| @contents << l}
      end
      
      # append the javascript highlighter just before the end of the pagestored contents
      highlight_js = "<script src='/javascripts/highlight.js'></script>"
      highlight_js << "<script>highlightSearchTerms('#{params[:word]}');</script>"
      highlight_js << "</body>"
      @contents = @contents.gsub(/<\/ *body *>/,highlight_js)
    end
    
  end
  
  def disclaimer
  end
  
end
