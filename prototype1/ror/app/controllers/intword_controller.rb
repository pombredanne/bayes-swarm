class IntwordController < ApplicationController
  scaffold :intword
  
  def show
    @intword = Intword.find(@params["id"], :include => [:language, :intword_statistic])
  end
  
  def edit
    @intword = Intword.find(@params["id"])
    @languages = Language.find_all
  end
  
  def new
    @intword = Intword.new
    @languages = Language.find_all
  end

  def cloud
    @intwords = Intword.find_popular(1)
  end
end
