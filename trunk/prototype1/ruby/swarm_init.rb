require 'yaml'

# Load global options
configFile = "swarm_shoal_options.yml"
$opts = YAML.load(File.open(configFile))

# Enables file storage if required
storage_opts = $opts['storage']
if storage_opts && storage_opts[:filesaver] == 'active'
  require 'extractor'
  require 'swarm_storage'
  
  # enrich extractors
  class HttpExtractor
    include Storage::FileSaver
  end
  
  class FileExtractor
    include Storage::FileSaver    
  end
  
  class RssExtractor
    include Storage::FileSaver    
  end
end