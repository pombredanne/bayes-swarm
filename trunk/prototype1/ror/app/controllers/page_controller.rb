class PageController < ApplicationController
  #scaffold :page
  layout "standard"

  def index
    list
    render :action => 'list'
  end
  
  def list
    @page_pages, @pages = paginate(:page,
                                   :per_page => 20,
                                   :conditions => "language_id = #{Locale.language.id}")
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
end
