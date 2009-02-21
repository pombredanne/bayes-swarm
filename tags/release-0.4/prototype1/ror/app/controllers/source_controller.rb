class SourceController < ApplicationController
  layout "standard"
  before_filter :authorize, :only => [:edit, :new, :destroy, :csv]

  def index
    list
    render :action => 'list'
  end
  
  def list
    sources_with_pages_in_cur_locale = Page.find(:all,
                                                 :conditions=>"language_id = #{Locale.language.id}",
                                                 :select=>"DISTINCT source_id AS id")
    @source_pages, @sources = paginate(:source,
                                       :per_page => 20,
                                       :conditions=>["id IN (?)", sources_with_pages_in_cur_locale])
  end
  
  def listall
    @source_pages, @sources = paginate(:source,
                                       :per_page => 20)
    render :action => 'list'
  end

  def new
    @source = Source.new
  end

  def create
    @source = Source.new(params[:source])
    
    if @source.save
      flash[:notice] = 'Source was successfully created.'
      redirect_to :action => 'new'
    else
      render :action => 'new'
    end
  end

  def edit
    @source = Source.find(params[:id])
  end

  def update
    @source = Source.find(params[:id])    
    
    if @source.update_attributes(params[:source])
      flash[:notice] = 'Source was successfully updated.'
      redirect_to :action => 'show', :id => @source.id
    else
      render :action => 'edit'
    end
  end
  
  def show
    @source = Source.find(params[:id])
  end
  
  def destroy
    @source = Source.find(params[:id])
    
    if @source.destroy()
      flash[:notice] = 'Source was successfully destroyed.'
      redirect_to :action => 'list'
    else
      flash[:notice] = 'Source was not successfully destroyed.'    
      redirect_to :action => 'list'
    end
  end

  def csv
    def generate_line(row)
      row_sep = $INPUT_RECORD_SEPARATOR
      [row, row_sep].join()
    end

    rows = nil
    header = nil
    Source.find(:all).each_with_index do |s, i|
      if i == 0
        header = generate_line(s.attributes.keys.join(','))
      end

      row = generate_line(s.attributes.values.join(','))
      rows = [rows, row].join()
    end

    csv = [header, rows].join

    send_data(csv,
              :type => 'text/csv; charset=iso-8859-1; header=present',
              :disposition => "attachment; filename=sources.csv")
  end

end
