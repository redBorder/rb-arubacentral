require 'yaml'

# Module to read and parse config.yml
module ConfigManager
  def self.load_config(config_file)
    unless File.exist?(config_file)
      puts "Config file '#{config_file}' not found."
      exit 1
    end

    config = YAML.load_file(config_file)

    config
  end
end
