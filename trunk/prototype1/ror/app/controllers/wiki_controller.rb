require 'hpricot'
require 'open-uri'

class WikiController < ApplicationController
  layout "standard"
  
  BASE_URL = "http://www.bayesfor.eu"
  
  def view
    url = ([] << params[:path]).flatten.join("/")

    doc = Hpricot(open(BASE_URL + "/wiki/" + url))
    
    # Some smart image resizing to comply with the limited size we 
    # have on the current bayes-swarm layout
    (doc/"div.page img").each do |img|
      img.set_attribute('src', BASE_URL + img.attributes["src"])
      if img.attributes['width']
        if img.attributes['width'] =~ /\d+/ && img.attributes['width'].to_i > 500
          img.set_attribute('width','500')
        end
      else
        img.set_attribute('width','80%')
      end
    end
    
    # URL rewriting to include the current locale in wiki URLs
    (doc/"div.page a").each do |a|
      if a.attributes["href"] =~ /^\/wiki/
        a.set_attribute('href', "/" + params[:locale] + a.attributes["href"]) 
      end
    end    
    
    # Remove the comment section, since it doesn't work
    (doc/"div.comment_wrapper").remove
    
    @wiki = (doc/"div.page")
    
  end
end
