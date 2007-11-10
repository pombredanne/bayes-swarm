class IntwordController < ApplicationController
  scaffold :intword
  helper   :plot
  layout   "standard"
  
  def show
    @intword = Intword.find(@params["id"], :include => [:language])
  end
  
  def edit
    @intword = Intword.find(@params["id"])
    @languages = Language.find(:all)
  end
  
  def new
    @intword = Intword.new
    @languages = Language.find_all
  end

  def cloud
    l_id = 1
    @attr = 'imp'
    @intwords = Intword.find_popular(l_id, 999999, @attr)    
  end
  
end
