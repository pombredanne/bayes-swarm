class HomeController < ApplicationController
  def index
    @n_intwords = Intword.find(:all).length
    @n_languages = Language.find(:all).length
    @n_words = Word.find(:all).length

    @intwords = Intword.find_by_sql "
        select intword_id, name, count(*) as freq
        from (

        SELECT w.intword_id, iw.name, date(w.scantime)
        FROM words w, pages p, intwords iw
        WHERE w.page_id=p.id and w.intword_id = iw.id and iw.language_id=1
        group by w.intword_id, iw.name, date(w.scantime)

        ) as a
        group by intword_id, name
        order by freq desc
        limit 50;"

    r = R_Config::R
    @r_dnorm = r.dnorm(1)
    end
end
