class IntwordController < ApplicationController
  helper   :plot
  layout   "standard"
  
  def index
    cloud
    render :action => 'cloud'
  end
  
  def show
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

  def edit
    @intword = Intword.find(params[:id])
  end

  def update
    @intword = Intword.find(params[:id])    
    
    if @intword.update_attributes(params[:intword])
      flash[:notice] = 'Intword was successfully updated.'
      redirect_to :action => 'show', :id => @intword.id
    else
      render :action => 'edit'
    end
  end
  
  def cloud
    @attr = 'imp'
    @action = 'show'
    @intwords = Intword.find_popular(Locale.language.id, 1, 999999, @attr, 1)
  end
  
  def notvisible_cloud
    @attr = 'imp'
    @action = 'edit'
    @intwords = Intword.find_popular(Locale.language.id, 1, 999999, @attr, 0)
  end
  
  def plot
    require 'gruff'
    g = Gruff::Line.new(480)
    g.title = "time series plot"

    intword_ids = params[:id].split("-")
    iwtses = ActiveSupport::OrderedHash.new()
    intword_ids.each do |iw_id|
      iw = Intword.find(iw_id)
      begin
        iwts = iw.get_time_series(params[:period]) 
        iwtses[iw] = iwts
      rescue RuntimeError
        #return nil
      end
    end
    
    if (iwtses != [])
      armonized_iwtses = IntwordTimeSeries.armonize(iwtses.values)
      iwtses.each_with_index do |iw, i|
        g.data(iw[0].name, armonized_iwtses[i].values)
      end
      g.labels = armonized_iwtses[0].labels
    else
      nil
    end
      
    send_data(g.to_blob, 
              :disposition => 'inline', 
              :type => 'image/png', 
              :filename => "ts.png")
  
  end  
  
  def pie
    require 'gruff'
    g = Gruff::Pie.new(480)
    g.title = "News Pie"

    intword_ids = params[:id].split("-")
    #intword_ids = "1-2".split("-")
    iwtses = ActiveSupport::OrderedHash.new()
    intword_ids.each do |iw_id|
      iw = Intword.find(iw_id)
      begin
        iwts = iw.get_time_series(params[:period]).values.sum
      rescue RuntimeError
        #return nil
      end
        
      if (iwts != [])
        g.data(iw.name, iwts)
      else
        nil
      end
    end  
    send_data(g.to_blob, 
              :disposition => 'inline', 
              :type => 'image/png', 
              :filename => "ts.png")
  
  end
end
