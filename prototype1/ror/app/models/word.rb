class Word < ActiveRecord::Base
  belongs_to :intword
  belongs_to :page
end
