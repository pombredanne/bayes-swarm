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

module Pulsar
  
  # Provides just an ultra-thin layer over the Hpricot library
  class Html
    
    attr_reader :doc
    
    def initialize(contents)
      @doc = Hpricot(contents)
      
      # strips away inline scripts and inline stylesheets.
      # This should leave us with a relatively clean webpage
      # (only semantic-ish tags)
      (@doc/"script").each { |script| script.inner_html = '' }
      (@doc/"style").each { |style| style.inner_html = '' }
    end
    
    def plain_text(xpath)
      @doc.search(xpath).map do |el|
        # links and other urls (such as img urls) are enclosed in brackets, 
        # so we strip them. We also remove html entities.
        el.to_plain_text.gsub(/\[.*?\]/, '').gsub(/&.*?;/," ")
      end
    end
    
    def all_plain_text(xpath)
      plain_text(xpath).join(" ")
    end
          
    # Return the keywords for the current document, as stored inside the
    # META tag. See http://en.wikipedia.org/wiki/Meta_tags
    def keywords
      all_keywords = @doc.search("//head/meta[@name='keywords']").map do |el|
        el.attributes["content"].split(",").map { |kw| kw.strip }
      end
      return all_keywords.flatten
    end
    
  end  
end