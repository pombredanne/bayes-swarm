class IntwordController < ApplicationController
  helper   :plot
  layout   "standard"
  
  def index
    cloud
    render :action => 'cloud'
  end
  
  def show
    #breakpoint "check"
    @ids= params[:id]
    intword_ids = @ids.split("-")
    @iws = Array.new()
    intword_ids.each do |iw_id|
      @iws << Intword.find(iw_id)
    end
  end
  
  def new
    @intword = Intword.new
  end

  def create
    @intword = Intword.new(params[:intword])
    
    if @intword.save
      flash[:notice] = 'Intword was successfully created.'
      redirect_to :action => 'new'
    else
      render :action => 'new'
    end
  end

  def cloud
    @attr = 'imp'
    @intwords = Intword.find_popular(Locale.language.id, 1, 999999, @attr)    
  end

  def plot
    require 'gruff'
    g = Gruff::Line.new(480)
    g.title = "time series plot"

    intword_ids = params[:id].split("-")
    iwtses = ActiveSupport::OrderedHash.new()
    intword_ids.each do |iw_id|
      iw = Intword.find(iw_id)
      iwts = iw.get_time_series(params[:period].to_i) 
      iwtses[iw] = iwts
    end
    
    armonized_iwtses = IntwordTimeSeries.armonize(iwtses.values)
    
    iwtses.each_with_index do |iw, i|
      g.data(iw[0].name, armonized_iwtses[i].values)
    end

    g.labels = armonized_iwtses[0].labels
    send_data(g.to_blob, 
              :disposition => 'inline', 
              :type => 'image/png', 
              :filename => "ts.png")
  
  end  
end
