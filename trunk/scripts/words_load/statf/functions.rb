class Functions
  def linear
    const_val = 3 
    return function { |x| const_val }
  end
  
  def smooth_sin
    damping = 0.1
    cycle = Math::PI / 10
    
    return function { |x| Math.sin( cycle * x) / ( damping * x ) }
  end
    
  ## DO NOT MODIFY BELOW THIS LINE
  def method_missing(methId, *args)
    puts "Undefined generation function #{methId.id2name}. If you need it, define it in stats/functions.rb"
  end
end