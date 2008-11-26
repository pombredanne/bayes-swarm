# Add date string parser class method to Date class.
#
class Date
  # Parse date string with one of the following formats:
  #
  # * -n[units]: Date from self: examples: '1d', '2d', '1m', '2y'
  #
  # The string argument is first converted to a string with #to_s.
  # Returns nil if passed nil or an empty string.
  # Raises ArgumentError if string can't be parsed.
  #
  def subtract_interval(string)
    string = string.to_s.strip.downcase
    return nil if string.empty?
    if string =~ /^(\d+)(\s*(d|w|m|y))?$/
      # Date intervals.
      n = $1.to_i
      units = $2
      case units
      when 'd'
        result = self - n
      when 'w'
        result = self - n*7
      when 'm'
        month = self.month - (n % 12)
        year = self.year - (n / 12)
        if month <1
          month += 12
          year -= 1
        elsif month > 12
          month -= 12
          year += 1
        end

        day = self.day
        while (Date.valid_civil?(year, month, day).nil?)
          day -= 1
        end
      
        result = Date.new(year, month, day)
      when 'y'
        # make sure the date is valid Date.new(2008, 2, 29).subtract_interval('1y') => 2008/02/28
        day = self.day
        while (Date.valid_civil?(self.year - n, self.month, day).nil?)
          day -= 1
        end
        result = Date.new(self.year - n, self.month, day)
      end
    else
      raise ArgumentError
    end
    result
  end

end
