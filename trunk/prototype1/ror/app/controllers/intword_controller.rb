class IntwordController < ApplicationController
  helper   :plot
  layout   "standard"
  
  def index  
    # cloud
    @attr = 'imp'
    @action = 'show'
    @intwords = Intword.find_popular(Locale.language.id, 1, 999999, @attr, 1)
  end
  
  def show
    @ids = params[:id]
    intword_ids = @ids.split("-")
    
    @iws = intword_ids.map { |id| Intword.find(id)}    
    @intervals = ['1y', '6m', '3m', '1m', '2w']
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
  
  def search
  end
  
  def find
    iw_search = params[:intword]
    @attr = 'imp'
    @intwords = Intword.find_popular(iw_search['language_id'], 1, 999999, @attr, nil, iw_search['name'])

    if (@intwords.empty?)
      flash[:notice] = "No words matched your search, try a shorter one, ie 'chin' instead of 'china'"
      redirect_to :action => 'search'
    elsif (@intwords.length == 1)      
      iw = @intwords.first
      # exact match => turn visibility on and show directly
      if (iw.name == iw_search[:name] && iw.visible == false)
        iw.visible = true
        iw.save
      end
      redirect_to :action => 'show', :id => iw.id
      
    else
      # not exact match => show cloud
      @action = 'show'
      render :action => 'cloud'
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
    g = Gruff::Line.new(500)
    g.hide_title = true

    intword_ids = params[:id].split("-")
    labels = nil
    intword_ids.each do |iw_id|
      iw = Intword.find(iw_id)
      begin
        iwts = iw.get_time_series(params[:period], true)
        g.data(iw.name, iwts.values)
        labels = iwts.labels
      rescue RuntimeError
        #return nil
      end
    end
    
    g.labels = labels
      
    send_data(g.to_blob, 
              :disposition => 'inline', 
              :type => 'image/png', 
              :filename => "ts.png")
  
  end  
  
  def pie
    require 'gruff'
    g = Gruff::Pie.new(500)
    g.title = "News Pie"
    # check empty stems
    intword_ids = params[:id].split("-")
    intword_ids.each do |iw_id|
      iw = Intword.find(iw_id)
      begin
        iwts = iw.get_time_series(params[:period]).values.sum
      rescue RuntimeError
        #return nil
      end
      if (iwts == nil ) 
        iwts = 0
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
  
  def csv
    def generate_line(row)
      row_sep = $INPUT_RECORD_SEPARATOR
      [row, row_sep].join()
    end
    
    iw_ids = params[:id].split("-")
    filename = "tmp/some_data.csv"
    iw_tss = Hash.new()
    
    dates = nil
    iw_ids.each do |iw_id|
      iw = Intword.find(iw_id)
      iw_ts = iw.get_time_series(params[:period], force_complete=true)
      iw_tss[iw] = iw_ts
      dates = iw_ts.dates
    end

    header = "date"
    iw_tss.each_key do |iw|
      header = [header, iw.name].join(',')
    end
    header = generate_line(header)
    
    rows = nil
    dates.each_with_index do |d, i|
      row = "#{d.strftime('%Y/%m/%d')}"
      iw_tss.each_pair do |k, v|
        row = [row, v.values[i]].join(',')
      end
      rows = [rows, generate_line(row)].join()
    end
    csv = [header, rows].join
    
    send_data(csv, 
              :type => 'text/csv; charset=iso-8859-1; header=present', 
              :disposition => "attachment; filename=some_data.csv")
  end
  
end
