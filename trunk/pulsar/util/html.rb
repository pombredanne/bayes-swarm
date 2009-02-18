# = Utilities : Html
# Contains utilities to parse and analyze html contents. 
# It uses Hpricot as the backend library to perform the heavy work.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'hpricot'

# Allocate 128Kb for parsing abnormally large attributes, that we have
# here and there. See http://code.whytheluckystiff.net/hpricot/ticket/13
Hpricot.buffer_size = 131072

module Pulsar
  
  # Provides just an ultra-thin layer over the Hpricot library
  class Html
    
    attr_reader :doc
    
    def initialize(contents)
      @doc = Hpricot(contents.gsub(/&.*?;/," "))
      
      # strips away inline scripts and inline stylesheets.
      # This should leave us with a relatively clean webpage
      # (only semantic-ish tags)
      (@doc/"script").each { |script| script.inner_html = nil }
      (@doc/"style").each { |style| style.inner_html = nil }
    end
    
    def plain_text(xpath)
      return @doc.search(xpath).map { |el| el.inner_text }.compact
    end
    
    def all_plain_text(xpath)
      plain_text(xpath).join(" ")
    end
          
    # Return the keywords for the current document, as stored inside the
    # META tag. See http://en.wikipedia.org/wiki/Meta_tags
    def keywords
      all_keywords = @doc.search("//head/meta[@name='keywords']").map do |el|
        content = el.attributes["content"]
        content.nil? ? "" : content.split(",").map { |kw| kw.strip }
      end
      return all_keywords.flatten
    end
    
  end  
end