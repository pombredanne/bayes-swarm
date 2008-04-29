require 'rubygems'
Dir.chdir('../../prototype1/ruby/')
require 'swarm_ar_support.rb'
require 'ferret'
 
class StopAndStemAnalyzer < Ferret::Analysis::Analyzer
  include Ferret::Analysis
 
  def token_stream(field, str, lang)
    stop_langs = {:it => Ferret::Analysis::FULL_ITALIAN_STOP_WORDS,
                  :en => Ferret::Analysis::EXTENDED_ENGLISH_STOP_WORDS}
    stem_langs = {:it => "italian",
                  :en => "english"}
    StemFilter.new(StopFilter.new(LowerCaseFilter.new(StandardTokenizer.new(str)),
                                  stop_langs[lang]),
                   stem_langs[lang])
  end
end

class StopAnalyzer < Ferret::Analysis::Analyzer
  include Ferret::Analysis
 
  def token_stream(field, str, lang)
    stop_langs = {:it => Ferret::Analysis::FULL_ITALIAN_STOP_WORDS,
                  :en => Ferret::Analysis::EXTENDED_ENGLISH_STOP_WORDS}
    StopFilter.new(LowerCaseFilter.new(StandardTokenizer.new(str)),
                                  stop_langs[lang])
  end
end

class StemAnalyzer < Ferret::Analysis::Analyzer
  include Ferret::Analysis
 
  def token_stream(field, str, lang)
    stem_langs = {:it => "italian",
                  :en => "english"}
    StemFilter.new(LowerCaseFilter.new(StandardTokenizer.new(str)),                                  
                   stem_langs[lang])
  end
end

def is_stop_word?(word)
  anal = StopAnalyzer.new
  stream = anal.token_stream(nil, word, :it)
  token = stream.next
  
  token.nil?
  
  # se !token.nil? -> #puts "la radice di #{word} è: #{token.text}"
end

def root(word)
  anal = StemAnalyzer.new
  stream = anal.token_stream(nil, word, :it)
  token = stream.next
  token.text
end
