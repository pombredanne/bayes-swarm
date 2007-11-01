class HomeController < ApplicationController
  layout "standard"

  def index
    @n_intwords = Intword.find(:all).length
    @n_languages = Language.find(:all).length
    @n_words = Word.find(:all).length

    @intwords = Intword.find_popular(1, 50, "n_hits")

#    r = R_Config::R
#    @r_dnorm = r.dnorm(1)
    end
end
