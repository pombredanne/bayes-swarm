class Page < ActiveRecord::Base
  belongs_to :source
  belongs_to :kind
  
  def self.fill_pages(params)
    params[:source] && params[:source] != '0' ? Source.find(params[:source]).pages.map { |p| p.id } : nil    
  end
  
end