class SourceController < ApplicationController
  layout "standard"
  # FIXME: add destroy
  before_filter :authorize, :only => [:edit]

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
  
end
