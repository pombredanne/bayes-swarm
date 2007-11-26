# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
    def font_size_for_tag_cloud_new( weight, lowest_w, highest_w, steps=5, size_max=26)
        return nil if weight.nil? or lowest_w.nil? or highest_w.nil?

        # work out the font size
        size_min = size_max - steps + 1
        thresholds = Array.new()
        
        norm_weight = (weight - lowest_w) / (highest_w - lowest_w).to_f
        
        rank = steps
        while norm_weight > Math.log(steps-rank+2)/Math.log(steps+1)
            rank -= 1
        end
        
        size = size_max - (rank - 1) * 4

        # FIXME: use 'style="font-size: 200%"'
        # display the results        
        size_txt = "font-size:#{ size.to_i.to_s }px;"
        return size_txt
    end

    def font_size_for_tag_cloud( weight, lowest_w, highest_w, steps=5, size_max=200, size_min=80)
        return nil if weight.nil? or lowest_w.nil? or highest_w.nil?

        # sizes array
        size_step = (size_max - size_min) / (steps - 1)
        sizes = Array.new()
        0.upto(steps-1) do |i|
          sizes << size_min + size_step * i
        end
        
        # thresholds
        thresholds = Array.new()
        thresholds << 1
        threshold_step = (size_max - size_min) / steps
        1.upto(steps) do |i|
          thresholds[i] = thresholds[i-1] + threshold_step
        end
        
        log_thresholds = Array.new()
        thresholds.each do |t|
          log_thresholds << Math.log(t)
        end

        norm_log_thresholds = Array.new()
        weight_thresholds = Array.new()
        log_thresholds.each_with_index do |t, i|
          norm_log_thresholds << t / log_thresholds[steps-1]
          weight_thresholds << highest_w * norm_log_thresholds[i]
        end
        
        rank = 1
        weight_thresholds.each_with_index do |wt, i|
          rank = i if (weight >= wt)
        end
        
        # display the results        
        size_txt = "font-size:#{ sizes[rank].to_s }%;"
        return size_txt
    end
  
  def path_builder()
    path = "Your are here: ".t
    case params[:controller]
    when 'home'
      case params[:action]
      when 'index'
        path = ""
      when 'doc'
        path += link_to("home", { :locale => params[:locale], :controller => "home"})
        path += " | doc"
      end
    else
      path += link_to("home", { :locale => params[:locale], :controller => "home"})
      case params[:action]
      when 'index'
        path += [" | ", params[:controller]].join
      else
        path += [" | ", link_to(params[:controller], { :locale => params[:locale], :controller => params[:controller]})].join
        path += [" | ", params[:action]].join
      end
    end
    path
  end

end
