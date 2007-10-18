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
end
