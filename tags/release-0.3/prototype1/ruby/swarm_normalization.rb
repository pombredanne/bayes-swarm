# Copyright 2007 Associazione Bayesfor. 
# Created by Matteo Zandi (matteo.zandi@bayesfor.eu)

require 'rubygems'
require 'ferret'
require 'yaml'

# A module which removes stopwords from ferret lists for the purpose
# of normalization
module Customlists
  @langs = [:it, :en]

  # ferret standard stopwords lists for italian and english
  def ferret_stopwords
    return {:it => Ferret::Analysis::FULL_ITALIAN_STOP_WORDS,
            :en => Ferret::Analysis::EXTENDED_ENGLISH_STOP_WORDS}
  end
  
  # bayesfor stopwords lists
  def bayesfor_stopwords
    # load stopwords to be kept
    stopwords_file = "swarm_stopwords.yml"
    stopwords_to_keep = YAML.load(File.open(stopwords_file))
    
    result = {}
    @langs.each do |l|
      result[l] = []
      ferret_stopwords[l].each {|w| result[l] << w unless stopwords_to_keep[l].include?(w)}
    end
    
    result
  end
end
