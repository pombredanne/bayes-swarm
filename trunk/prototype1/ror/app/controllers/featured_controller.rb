class FeaturedController < ApplicationController
  layout "standard"
  
  def usprimary2008
    # def interesting words for usprimary2008
    @candidate={"all" => "330-331-333-321-332", 
            "rep" => "333-335-340-341-331",
            "dem" => "321-330-332-348-338" }
    if ( params[:id] == nil )
      params[:id] = @candidate["rep"]
    end

    @intword_ids = params[:id].split("-")

    @ofcgraph = open_flash_chart_object(500,375, "/#{params[:locale]}/ofc/pie/#{params[:id]}", false, '/')    
  end

  def usprimary2008_timeview
    # def interesting words for usprimary2008
    @candidate={"all" => "330-331-333-321-332", 
            "rep" => "333-335-340-341-331",
            "dem" => "321-330-332-348-338" }
    if ( params[:id] == nil )
      params[:id] = @candidate["rep"]
    end

    @ofcgraph = open_flash_chart_object(500,375, "/#{params[:locale]}/ofc/line/#{params[:id]}/#{params[:period]}", false, '/')

  end
  
  def ita2008
    ids = "98-115-118-3370"
    @ofcgraph = open_flash_chart_object(500,375, "/#{params[:locale]}/ofc/pie/#{ids}", false, '/')    
  end  
  
end
