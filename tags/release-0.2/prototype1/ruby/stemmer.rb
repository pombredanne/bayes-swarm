require 'rubygems'
gem 'ferret'
require 'ferret'

class FerretStemmer
  
  def stem(content, lang)
    langs = {:ita => Ferret::Analysis::FULL_ITALIAN_STOP_WORDS,
             :eng => Ferret::Analysis::EXTENDED_ENGLISH_STOP_WORDS}
  
    analyzer = StopAndStemAnalyzer.new
    stream = analyzer.token_stream(nil, content, langs[lang])
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
    return StemFilter.new(StopFilter.new(LowerCaseFilter.new(StandardTokenizer.new(str)), lang))
  end
end
