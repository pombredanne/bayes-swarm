require "net/http"

class HttpExtractor
  
  def extract(url)
   response = extract_with_redirect(url)
   response.body
  end
  
  def extract_with_redirect(url, limit=10)
    fail "#{self.class.name}: http redirect too deep" if limit.zero?
    puts "#{self.class.name}: Trying: #{url}"
    response = Net::HTTP.get_response(URI.parse(url))
    case response
    when Net::HTTPSuccess
      response
    when Net::HTTPRedirection
      extract_with_redirect(response['location'],limit-1)
    else
      response.error!
    end
  end
  
end

class FileExtractor
  
  def extract(filename)
    content = ""
    File.open(filename) do |file| 
      while line = file.gets 
        content << " " << line 
      end 
    end
    return content
  end
  
end