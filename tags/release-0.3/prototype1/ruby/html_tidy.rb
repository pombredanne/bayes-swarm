class HtmlTidy
  
  def clean(content)
    strip_tags_and_entities(tidy(content))
  end
  
  def tidy(content)
      File.open("tidy.tmp","w") do |file|
        file.puts content
      end
      clean_content = %x{ tidy tidy.tmp }
      File.delete("tidy.tmp")
      
      return clean_content
  end
  
  def strip_tags_and_entities(content)
    one_liner = ""
    content.each_line do |line|
      one_liner += line.chomp + " "
    end
    one_liner.gsub(/<.*?>/,"").gsub(/&.*?;/," ")
  end
end