class IntwordController < ApplicationController
  helper   :plot
  layout   "standard"
  
  def show
    @intword = Intword.find(@params["id"])
  end
  
  def new
    @intword = Intword.new
    @languages = Language.find_all
  end

  def cloud
    @attr = 'imp'
    @intwords = Intword.find_popular(Locale.language.id, 999999, @attr)    
  end

  def plot
    iw = Intword.find(@params["id"])
    iwts = iw.get_time_series(3) 
    
    require 'gruff'
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
