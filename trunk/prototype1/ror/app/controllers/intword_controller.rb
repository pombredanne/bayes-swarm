class IntwordController < ApplicationController
  scaffold :intword
  layout "standard"
  
  def show
    @intword = Intword.find(@params["id"], :include => [:language, :intword_statistic])
  end
  
  def edit
    @intword = Intword.find(@params["id"])
    @languages = Language.find_all
  end
  
  def new
    @intword = Intword.new
    @languages = Language.find_all
  end

  def cloud
    @intwords = Intword.find_popular(1)
  end

  def demogruff
    require 'gruff'
    iw = Intword.find(@params["id"])
    
    g = Gruff::Line.new(480)
    g.title = iw.name

    tseries = iw.intword_time_series.find(:all, :conditions=>"date>'#{Date.today()<<3}'", :order=>"date")
    data = Array.new()
    labels = Array.new()
    tseries.each do |ts|
      data << ts.count
      #labels << ts.date
    end

    g.data(iw.name, data)
    #g.data("Oranges", [4, 8, 7, 9, 8, 9])
    #g.data("Watermelon", [2, 3, 1, 5, 6, 8])
    #g.data("Peaches", [9, 9, 10, 8, 7, 9])

    #g.labels = {0 => '2003', 2 => '2004', 4 => '2005'}

    filename = "tmp/cache/intword_ts_#{iw.id}.png"
    
    # this writes the file to the hard drive for caching
    # and then writes it to the screen.
  
    g.write(filename)
    send_file filename, :type => 'image/png', :disposition => 'inline'
  end
end
