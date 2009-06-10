class Page < ActiveRecord::Base
  belongs_to :source
  belongs_to :kind
end