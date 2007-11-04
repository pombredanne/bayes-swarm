class HomeController < ApplicationController
  layout "standard"

  def index
    @n_intwords = Intword.find(:all).length
    @n_languages = Language.find(:all).length
    @n_words = Word.find(:all).length

    l_id = 1
    @attr = 'imp'
    @intwords = Intword.find_popular(l_id, 50, @attr)
#    r = R_Config::R
#    @r_dnorm = r.dnorm(1)
    end
end
