class IntwordController < ApplicationController
  scaffold :intword
  
  def show
    @intword = Intword.find(@params["id"], :include => :language)
    @n_words = Word.find(:all, :conditions => {:intword_id => @params["id"]}).length
  end
  
  def edit
    @intword = Intword.find(@params["id"])
    @languages = Language.find_all
  end
  
  def new
    @intword = Intword.new
    @languages = Language.find_all
  end

  def cloud
    @intwords = Intword.find_by_sql "
        select intword_id, name, count(*) as freq
        from (

        SELECT w.intword_id, iw.name, date(w.scantime)
        FROM words w, pages p, intwords iw
        WHERE w.page_id=p.id and w.intword_id = iw.id and iw.language_id=1
        group by w.intword_id, iw.name, date(w.scantime)

        ) as a
        group by intword_id, name
        order by freq desc"
  end
end
