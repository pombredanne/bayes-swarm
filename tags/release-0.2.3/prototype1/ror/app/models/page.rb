class Page < ActiveRecord::Base
  belongs_to :source
  belongs_to :kind
  belongs_to :language
  has_many :word, :dependent => :destroy

  validates_presence_of :url
  
  def before_create
    self.created_at = Time.now()
  end
    
end
