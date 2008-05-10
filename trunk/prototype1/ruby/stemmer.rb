require 'rubygems'
require 'ferret'
require 'swarm_normalization'

include Customlists

class FerretStemmer
  def initialize    
    @langs = Customlists.bayesfor_stopwords
  end
  
  def stem(content, lang)
    analyzer = StopAndStemAnalyzer.new
    stream = analyzer.token_stream(nil, content, @langs[lang])
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
  
  def token_stream(field, str, lang)
    if lang == :en
      return StemFilter.new(StopFilter.new(LowerCaseFilter.new(StandardTokenizer.new(str)), lang))
    else
      return StopFilter.new(LowerCaseFilter.new(StandardTokenizer.new(str)), lang)
    end
  end
end
