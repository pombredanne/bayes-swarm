class PageController < ApplicationController
  layout "standard"
  before_filter :authorize, :only => [:edit, :new, :destroy]
  
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
end
