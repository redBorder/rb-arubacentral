require_relative './helpers/codecov_helper.rb'
require_relative '../src/helpers/aruba_config.rb'
require 'test/unit'
require 'yaml'

# Test Config Manager
class ConfigManagerTest < Test::Unit::TestCase
  def setup
    @config_file = './src/config.yml'
  end

  def test_load_config_with_valid_config_file
    config = ConfigManager.load_config(@config_file)

    assert_not_nil config
  end

  def test_load_config_with_invalid_config_file
    config_file = 'invalid_config.yml'

    assert_raises SystemExit do
      ConfigManager.load_config(config_file)
    end
  end
end
