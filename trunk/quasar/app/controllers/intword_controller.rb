class IntwordController < ApplicationController
  
  # TODO: should be removed or transformed into a 'pre-configured' visualization
  def show
    @iws = Intword.find(params[:id].split('-'))
    @focuspage = params[:page] ? Page.find_by_id(params[:page]) : nil
    @pages = Page.find(:all)
  end
  
  def create
  end
  
  def ac
    matches = {
      'query' => params[:query] ,
      'suggestions' => [],
      'data' => [],
    }
    
    Intword.find(
      :all, 
      :conditions => [ 'name like ? and iso_639_1 = ?', "#{params[:query]}%" , "#{params[:lang] || "en"}"], 
      :order => "visible DESC",
      :joins => "LEFT JOIN globalize_languages on globalize_languages.id = language_id",
      :include => [ :language ],
      :limit => 20).each do |iw| 
        matches['suggestions'] << iw.name
        matches['data'] << iw.id
      end
    render :json => matches.to_json
  end
end