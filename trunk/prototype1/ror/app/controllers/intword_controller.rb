class IntwordController < ApplicationController
  scaffold :intword
  helper   :plot
  layout   "standard"
  
  def show
    @intword = Intword.find(@params["id"], :include => [:language])
  end
  
  def edit
    @intword = Intword.find(@params["id"])
    @languages = Language.find(:all)
  end
  
  def new
    @intword = Intword.new
    @languages = Language.find_all
  end

  def cloud
    l_id = 1
    @attr = 'imp'
    @intwords = Intword.find_popular(l_id, 999999, @attr)    
  end

  def plot
    iw = Intword.find(@params["id"])
    iwts = iw.get_time_series(3) 
    
    g = Gruff::Line.new(480)
    g.title = iw.name
    g.labels = iwts.labels
    
    g.data(iw.name, iwts.values)
    
    send_data(g.to_blob, 
              :disposition => 'inline', 
              :type => 'image/png', 
              :filename => "ts.png")
  
  end  
end
