class IgController < ApplicationController
  
  def elections  
    # def interesting words for usprimary2008
    @candidate={"all" => "330-331-333-321-332", 
            "rep" => "333-335-340-341-331",
            "dem" => "321-330-332-348-338", 
            "ita" => "98-115-118-3370" }
    if ( params[:id] == nil )
      if params[:party]
        params[:id] = @candidate["all"] if params[:party] == "All"
        params[:id] = @candidate["rep"] if params[:party] == "Republicans"
        params[:id] = @candidate["dem"] if params[:party] == "Democrats"
        params[:id] = @candidate["ita"] if params[:party] == "ita"
      else
        params[:id] = @candidate["rep"]
      end
    end
    
    @intword_ids = params[:id].split("-")
    
    @ofcgraph = open_flash_chart_object('100%','100%', "/#{params[:locale]}/ofc/pie/#{params[:id]}?kind=igoogle&party=#{params[:party]}", false, '/')    
  end
    
  def word
    @party = params[:party]
    @iw_id = params[:id]
    @period = "1m"
    @ofcgraph = open_flash_chart_object('100%','90%', "/#{params[:locale]}/ofc/line/#{params[:id]}/#{@period}?kind=igoogle", false, '/')
  end
  
  
end
