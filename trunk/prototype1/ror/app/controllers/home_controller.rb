class HomeController < ApplicationController
  layout "standard"

  def index
    @n_intwords = Intword.find(:all).length
    @n_languages = LOCALES.length
    @n_words = Word.find(:all).length

    @attr = 'imp'
    @intwords = Intword.find_popular(Locale.language.id, 50, @attr)
#    r = R_Config::R
#    @r_dnorm = r.dnorm(1)
    end
end
