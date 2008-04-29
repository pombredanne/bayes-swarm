class PageController < ApplicationController
  layout "standard"
  before_filter :authorize, :only => [:edit, :new, :destroy, :csv]
  
  def index
    list
    render :action => 'list'
  end
  
  def list
    @page_pages, @pages = paginate(:page,
                                   :per_page => 20,
                                   :conditions => "language_id = #{Locale.language.id}")
  end

  def new
    @page = Page.new
  end

  def create    
    @page = Page.new(params[:page])
    @page.last_scantime = 0
    
    if @page.save
      flash[:notice] = 'Page was successfully created.'
      redirect_to :action => 'new'
    else
      render :action => 'new'
    end
  end
    
  def edit
    @page = Page.find(params[:id])
  end

  def update
    @page = Page.find(params[:id])    
    
    if @page.update_attributes(params[:page])
      flash[:notice] = 'Page was successfully updated.'
      redirect_to :action => 'show', :id => @page.id
    else
      render :action => 'edit'
    end
  end
  
  def show
    @page = Page.find(params[:id])
  end
  
  def destroy
    @page = Page.find(params[:id])
    
    if @page.destroy()
      flash[:notice] = 'Page was successfully destroyed.'
      redirect_to :action => 'list'
    else
      flash[:notice] = 'Page was not successfully destroyed.'    
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
    Page.find(:all).each_with_index do |p, i|
      if i == 0
        header = generate_line(p.attributes.keys.join(','))
      end
      
      row = generate_line(p.attributes.values.join(','))
      rows = [rows, row].join()
    end
    
    csv = [header, rows].join

    send_data(csv,
              :type => 'text/csv; charset=iso-8859-1; header=present',
              :disposition => "attachment; filename=pages.csv")
  end

end
