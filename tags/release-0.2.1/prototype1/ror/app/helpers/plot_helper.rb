
# Provides a tag for embedding gruff graphs into your Rails app.
#
# To use, load it in your controller with
#
#   helper :gruff
#
# AUTHOR
#
# Carlos Villela [mailto:cv@lixo.org]
# Geoffrey Grosenbach[mailto:boss@topfunky.com]
#
# http://lixo.org
# http://topfunky.com
# 
# License
#
# This code is licensed under the MIT license.
#
module PlotHelper

  # Call with a name-values hash and an options hash (title and labels supported for now).
  # You can also pass :class => 'some_css_class' ('gruff' by default).
  def plot_tag(data={}, opts={}, type="ts")
   
    @session['gruff_opts']=opts
    @session['gruff_data']=data
   
    "<img src=\"/plot/#{type}\" class=\"#{opts[:class] || 'gruff'}\" alt=\"Gruff Graph\" />"
  end

end
