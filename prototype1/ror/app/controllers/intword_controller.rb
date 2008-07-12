class IntwordController < ApplicationController
  layout   "standard"
  # FIXME: add delete
  before_filter :authorize, :only => [:edit, :notvisible_cloud, :csv]

  def index  
    # cloud
    @attr = 'imp'
    @action = 'show'
    @intwords = Intword.find_popular(Locale.language.id, '1m', 999999, @attr, 1)
  end
  
  def show
    @ids = params[:id]
    intword_ids = @ids.split("-")
    
    @iws = intword_ids.map { |id| Intword.find(id)}    
    @intervals = ['1y', '6m', '3m', '1m', '2w']
    
    @ofcgraph = open_flash_chart_object(500,375, "/#{params[:locale]}/ofc/line/#{params[:id]}/#{params[:period]}", false, '/')     
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
    @intwords = Intword.find_popular(iw_search['language_id'], '1m', 999999, @attr, nil, iw_search['name'])

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
    @intwords = Intword.find_popular(Locale.language.id, '1m', 999999, @attr, 1)
  end
  
  def notvisible_cloud
    @attr = 'imp'
    @action = 'edit'
    @intwords = Intword.find_popular(Locale.language.id, '2w', 499, @attr, 0)
  end
  
  def corr_matrix
    @iws, @iws_corr = Intword.find_correlation_matrix(Locale.language.id, '1m', 9)
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

  def csv_cloud
    def generate_line(row)
      row_sep = $INPUT_RECORD_SEPARATOR
      [row, row_sep].join()
    end
    
    filename = "tmp/some_data.csv"
    attributes = ["visible", "name", "imp", "id", "language_id"]
    
    rows = nil
    iws = Intword.find_popular(Locale.language.id, params[:period], 499, 'imp')
    iws.each do |iw|
        row = iw.attributes.values.join(',')
        rows = [rows, generate_line(row)].join()
    end
    header = generate_line(iws[0].attributes.keys.join(','))
    
    csv = [header, rows].join
    
    send_data(csv, 
              :type => 'text/csv; charset=iso-8859-1; header=present', 
              :disposition => "attachment; filename=some_data.csv")
  end
end
