class Kind < ActiveRecord::Base
  has_many :pages
  
  def self.fill_kind(params)
    kind = Kind.find_by_kind(params[:kind])
    if kind
      kind.kind
    else
      nil
    end
  end
  
end