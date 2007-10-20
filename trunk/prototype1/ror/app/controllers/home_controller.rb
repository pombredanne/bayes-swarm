class HomeController < ApplicationController
  def index
    @n_int_words = IntWord.find(:all).length
    @n_languages = Language.find(:all).length
    @n_words = Word.find(:all).length

    @int_words = IntWord.find_by_sql "
        select id, name, count(*) as freq
        from (

        SELECT a.id, c.name, date(a.scantime)
        FROM words a, pages b, int_words c
        WHERE a.page_id=b.id and a.id = c.id and c.language='eng'
        group by a.id,c.name, date(a.scantime)

        ) as a
        group by id,name
        order by freq desc
        limit 50;"

    r = R_Config::R
    @r_dnorm = r.dnorm(1)
    end
end
