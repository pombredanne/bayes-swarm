class IntwordController < ApplicationController
  scaffold :intword
  layout "standard"
  
  def show
    @intword = Intword.find(@params["id"], :include => [:language, :intword_statistic])
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
  
  def ts_plot
    require 'gruff'
    iw = Intword.find(@params["id"])
    ts = iw.get_time_series(3)
    data = ts.values
    labels = ts.labels

    g = Gruff::Line.new(480)
    g.title = iw.name
    g.data(iw.name, data)
    g.labels = labels

    send_data(g.to_blob,
              :disposition => 'inline', 
              :type => 'image/png', 
              :filename => "intword_ts.png")    
  end  
  
end
