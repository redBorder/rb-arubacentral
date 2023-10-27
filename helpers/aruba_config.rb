require 'yaml'

module ConfigManager
  CONFIG_FILE_PATH = 'config.yml'

  def self.load_config

    unless File.exist?(CONFIG_FILE_PATH)
      puts "Config file '#{CONFIG_FILE_PATH}' not found."
      exit 1
    end

    config = YAML.load_file(CONFIG_FILE_PATH)

    config
  end
end
