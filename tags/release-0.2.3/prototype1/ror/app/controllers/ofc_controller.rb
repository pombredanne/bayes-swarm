class OfcController < ApplicationController

  DEFAULT_OPTIONS = {
    :kind => :default,
    :graph_colors => [ '#fffc23' , '#616BDB' , '#65AB45' , '#BE4F3C' , '#824D7D' ],
    :bg_color => '#000000',
    :pie_bg_color => '#222222',
    :inner_background => ["#000000", "#444444"],
    :x_axis => '#ffffff',
    :x_axis_grid => '#444444',
    :y_axis => '#ffffff',
    :title_color => '#ffffff',
    :title => "Words' count graph",
    :pie_line => '#ffffff',
    :pie_label => '#ffffff'
    
  }
  
  IGOOGLE_OPTIONS = {
    :kind => :igoogle,
    :graph_colors => [ '#84B7E4', '#A8F7DF', '#687C98' , '#CCFFFF' , '#A99ED3' ],
    :bg_color => '#ffffff',
    :pie_bg_color => '#ffffff',
    :inner_background => [ "#ffffff", "#D9FDFF" ],
    :x_axis => '#000000',
    :x_axis_grid => '#cccccc',
    :y_axis => '#000000',
    :title_color => '#000000',
    :title => "Recent popularity",
    :pie_line => '#000000',
    :pie_label => '#000000'    
  }
  
  def get_options
    params[:kind] && params[:kind] == "igoogle" ? IGOOGLE_OPTIONS : DEFAULT_OPTIONS
  end
  private :get_options
  
  def igoogle?
    get_options[:kind] == :igoogle
  end
  
  def empty_graph(g, options)
    g.set_x_label_style( 10, options[:x_axis], 2)

    g.set_x_labels([ Date.today ])        

    g.set_y_min(0) 
    g.set_y_max(20)

    g.set_y_label_steps(10)  
    g.set_y_label_style( 10, options[:y_axis]);
    g.set_num_decimals(0)  
    g.set_data([0])
    g.line_dot(2, 4, options[:graph_colors][0] , "No data")  
    g.set_title("No data", "{font-size: 24px; font-weight: bolder; color: #{options[:title_color]}}")    
  end
  private :empty_graph
  
  def line
    options = get_options
    
    g = Graph.new
    g.set_bg_color(options[:bg_color])
    g.set_inner_background(options[:inner_background][0], options[:inner_background][1] , 90)
    g.set_x_axis_color(options[:x_axis])
    g.set_y_axis_color(options[:y_axis])    
    
    colors = options[:graph_colors]    
    mins, maxs = [], []
    valsize = nil
    dates = nil
      
    col_count = 0
    intword_ids = params[:id].split("-")
    intword_ids.each do |iw_id|
      iw = Intword.find(iw_id)
      begin
        iwts = iw.get_time_series(params[:period], intword_ids.length > 1)
        
        mins << iwts.values.map{|x| x.nil? ? 0 : x }.min
        maxs << iwts.values.map{|x| x.nil? ? 0 : x }.max
      
        valsize ||= iwts.values.size
        dates ||= iwts.dates

        g.set_data(iwts.values.map{|x| x.nil? ? 0 : x })
        lcount = -1;
        unless igoogle?
          g.set_links(iwts.values.map{|x| lcount += 1; "javascript:breakdown('" + url_for(:controller => "pagestore" , :action => "show" , :date => dates[lcount] , :id => params[:id]) + "')" })
        end
        g.line_dot(2, 4, colors[ col_count % colors.size] , iw.name, 10)
        
        col_count += 1
      rescue RuntimeError
        #return nil
      end
    end 
    
    if valsize.nil?
      empty_graph(g, options)
    else 
      g.set_x_label_style( 10, options[:x_axis], 2, valsize/6, options[:x_axis_grid] )
      g.set_x_axis_steps(valsize/6)

      g.set_x_labels(dates)        

      g.set_y_min(mins.min) 
      g.set_y_max(maxs.max)

      g.set_y_label_steps(10)  
      g.set_y_label_style( 10, options[:y_axis]);
      g.set_num_decimals(0)      
      g.set_title(options[:title], "{font-size: 18px; font-weight: bolder; color: #{options[:title_color]}}")
    end
      
    g.set_tool_tip("#key#<br>#x_label# (#val# occurrences)")

    render :text => g.render
  end
  
  def pie
    
    options = get_options

    g = Graph.new    
    g.set_bg_color(options[:pie_bg_color])

    if igoogle?
      g.set_bg_image("/images/bayes_logo_small.png","left","top")
    else
      g.set_title( "News Pie",  "{font-size: 24px; font-weight: bolder; color: #{options[:title_color]}}")      
    end

    # check empty stems
    intword_ids = params[:id].split("-")
    
    values = []
    labels = []
    links = []
    intword_ids.each do |iw_id|
      iw = Intword.find(iw_id)
      iwts = nil
      begin
        iwts = iw.get_time_series(params[:period]).values.sum
        values << (iwts ||= 0)
        labels << iw.name        
        if igoogle?
          links << url_for( :controller => "ig", :action => "word" , :id => iw_id , :locale => "en" , :party => params[:party])
        else
          links << url_for( :controller => "intword", :action => "show" , :id => iw_id , :locale => "en" )
        end
      rescue RuntimeError
        #return nil
      end
    end
    
    g.pie(90,options[:pie_line],"{font-size: 12px; color: #{options[:pie_label]};")
    g.pie_values(values, labels, links)  
    g.pie_slice_colors(options[:graph_colors])
    render :text => g.render
  end
  
end
