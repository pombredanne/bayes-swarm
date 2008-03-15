class Source < ActiveRecord::Base  
  has_many :pages, :dependent => :destroy
  has_many :words, :through => :pages
  
  validates_presence_of :name
  
  def before_create
    self.created_at = Time.now()
  end
  
end
