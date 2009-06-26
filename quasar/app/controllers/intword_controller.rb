class IntwordController < ApplicationController
  
  # TODO: should be removed or transformed into a 'pre-configured' visualization
  # def show
  #   @gviz_url = request.request_uri.gsub(/\/intword\/show/,"/gviz/#{params[:type]}").gsub(/&type=[^&]+/,'')
  #   @sources = Source.find(:all).sort_by { |s| s.name }
  # end
  
  def create
    @sources = Source.find(:all).sort_by { |s| s.name }
  end
  
  def wordlookup
  end
  
  def search
    iws = Intword.fill_intwords(params)
    simplified_iws = iws.map do |iw|
      { :id => iw.id, :name => iw.name, :language => iw.language.name }
    end
    puts simplified_iws.inspect
    render :json => simplified_iws.to_json
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