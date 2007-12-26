class HomeController < ApplicationController
  layout "standard"

  def index
    @n_intwords = Intword.count(:conditions => "visible=1")
    @n_languages = LOCALES.length
    @n_words = Word.count().localize

    @attr = 'imp'
    @action = 'show'
    @intwords = Intword.find_popular(Locale.language.id, 1, 50, @attr, 1)
#    r = R_Config::R
#    @r_dnorm = r.dnorm(1)
  end
    
  def doc
  end


  def usprimary2008
    # def interesting words for usprimary2008
    @candidate_id = "330-333-321-332-335"
    intword_ids = @candidate_id.split("-")
    
    @candidate_series = Array.new() 
    @candidate_names  = Array.new()
    count = 0
    intword_ids.each do |iw_id|
      
      iw = Intword.find(iw_id)
      begin
        @candidate_series[count] = iw.get_time_series("3w").values
        @candidate_names[count] = iw.name
      rescue RuntimeError
        #return nil
      end
      count += 1
    end
        

  end
  
end

class SpecialReportController < ApplicationController
  helper :sparklines

end