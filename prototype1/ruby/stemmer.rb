require 'rubygems'
gem 'ferret'
require 'ferret'

class FerretStemmer
  
  def stem(content)
    analyzer = StopAndStemAnalyzer.new
    stream = analyzer.token_stream(nil,content)
    token = stream.next
    res = []
    until token.nil?
      res << token.text
      token = stream.next
    end
    
    return res
  end
  
end

class StopAndStemAnalyzer < Ferret::Analysis::Analyzer
  include Ferret::Analysis
  
  def token_stream(field, str)
    return StemFilter.new(StopFilter.new(LowerCaseFilter.new(StandardTokenizer.new(str)),Ferret::Analysis::FULL_ITALIAN_STOP_WORDS))
  end
end