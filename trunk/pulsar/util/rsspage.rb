# = Utilities : RssPage
# Contains the definition of a simple wrapper class that represents
# an RSS item.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v22 License.

module Pulsar
  
  # An utility class to wrap a +url+, +kind+ and +language+
  # into a +page+ construct, specifically for an RSS item.  
  class RssItemPage
    attr_reader :url, :id, :kind_name, :language_name
    def initialize(url, id, language_name)
      @url = url
      @id = id
      @kind_name = "rssitem"
      @language_name = language_name
    end
  end
end