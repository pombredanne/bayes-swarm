class IntWordController < ApplicationController
  scaffold :int_word
  
  def new
    @int_word = IntWord.find(@params["id"], :include => :language)
  end
  
  def edit
    @int_word = IntWord.find(@params["id"])
    @languages = Language.find_all
  end
  
  def new
    @int_word = IntWord.new
    @languages = Language.find_all
  end

  def cloud
    @int_words = IntWord.find_by_sql "
        select id, name, count(*) as freq
        from (

        SELECT a.id, c.name, date(a.scantime)
        FROM words a, pages b, int_words c
        WHERE a.page_id=b.id and a.id = c.id and c.language_id=1
        group by a.id,c.name, date(a.scantime)

        ) as a
        group by id,name
        order by freq desc"
  end
end
