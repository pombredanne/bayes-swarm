class Page < ActiveRecord::Base
  belongs_to :source
  belongs_to :kind
  belongs_to :language
end
