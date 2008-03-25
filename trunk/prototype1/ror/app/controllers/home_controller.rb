class HomeController < ApplicationController
  layout "standard"

  def index
    @n_intwords = Intword.count(:conditions => "visible=1")
    @n_languages = LOCALES.length
    @n_words = Word.count().localize

    @attr = 'imp'
    @action = 'show'
    @intwords = Intword.find_popular(Locale.language.id, '1m', 50, @attr, 1)
#    r = R_Config::R
#    @r_dnorm = r.dnorm(1)
  end
    
  def doc
  end


  def usprimary2008
    # def interesting words for usprimary2008
    @candidate={"all" => "330-331-333-321-332", 
       "rep" => "333-335-340-341-334-347",
       "dem" => "330-321-332-339-338-348-346-337-336" }
    @candidate={"all" => "330-331-333-321-332", 
            "rep" => "333-335-340-341-331",
            "dem" => "321-330-332-348-338" }
    if ( params[:id] == nil )
      params[:id] = @candidate["rep"]
    end
    
    
   
    @intword_ids = params[:id].split("-")
    
    @ofcgraph = open_flash_chart_object(500,375, "/#{params[:locale]}/ofc/pie/#{params[:id]}", false, '/')    
    
#    @candidate_series = Array.new() 
#    @candidate_names  = Array.new()
#    count = 0
#    intword_ids.each do |iw_id|
      
#      iw = Intword.find(iw_id)
#      begin
#        @candidate_series[count] = iw.get_time_series("3w").values
#        @candidate_names[count] = iw.name
#      rescue RuntimeError
#        #return nil
#      end
#      count += 1
#    end
        

  end
    def usprimary2008_timeview
      # def interesting words for usprimary2008
      @candidate={"all" => "330-331-333-321-332", 
         "rep" => "333-335-340-341-334-347",
         "dem" => "330-321-332-339-338-348-346-337-336" }
      @candidate={"all" => "330-331-333-321-332", 
              "rep" => "333-335-340-341-331",
              "dem" => "321-330-332-348-338" }
      if ( params[:id] == nil )
        params[:id] = @candidate["rep"]
      end

    @ofcgraph = open_flash_chart_object(500,375, "/#{params[:locale]}/ofc/line/#{params[:id]}/#{params[:period]}", false, '/')

    end 
end
