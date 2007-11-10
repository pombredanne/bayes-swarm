class PageController < ApplicationController
  scaffold :page
  
  def edit
    @page = Page.find(@params["id"])
    @sources = Source.find_all
    @languages = Language.find_all
  end
  
  def show
    @page = Page.find(@params["id"], :include => [:source, :language])
  end
end
