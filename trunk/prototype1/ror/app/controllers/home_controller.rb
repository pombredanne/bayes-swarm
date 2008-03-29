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


end
