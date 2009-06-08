class Language < ActiveRecord::Base
  set_table_name "globalize_languages"
  
  def name
    iso_639_1
  end
end