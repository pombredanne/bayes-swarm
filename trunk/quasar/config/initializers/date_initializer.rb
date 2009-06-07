class Date
  def self.from_interval(string)
    string = string.to_s.strip.downcase
    if string =~ /^(\d+)(\s*(d|w|m|y))?$/
      n = $1.to_i
      units = $2
      case units
      when 'd'
        n.days.ago
      when 'w'
        n.weeks.ago
      when 'm'
        n.months.ago
      when 'y'
        n.years.ago
      end
    else
      raise ArgumentError
    end
  end
end