class IntwordController < ApplicationController
  
  # TODO: should be removed or transformed into a 'pre-configured' visualization
  def show
    @iws = Intword.find(params[:id].split('-'))
    @focuspage = params[:page] ? Page.find_by_id(params[:page]) : nil
    @pages = Page.find(:all)
  end
  
  def create
  end
end