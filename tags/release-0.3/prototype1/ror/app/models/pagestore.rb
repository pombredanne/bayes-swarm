class PageStore
  
  attr_reader :counts, :words, :pages, :total
  
  def initialize
    @counts = {}
    @words = {}
    @total = 0
  end
  
  def add(intword,page_id,count)
    @words[intword] ||= intword.id
    page ||= Page.find(page_id)

    @counts[page] ||= {}
    @counts[page][intword.name] ||= 0    
    @counts[page][intword.name] += count
    
    @total += count
  end
  
end

