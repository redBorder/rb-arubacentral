#######################################################################
# Copyright (c) 2023 ENEO Tecnologia S.L.
# This file is part of redBorder.
# redBorder is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# redBorder is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License
# along with redBorder. If not, see <http://www.gnu.org/licenses/>.
#######################################################################

require_relative './helpers/codecov_helper'
require_relative '../lib/helpers/aruba_config'
require 'test/unit'
require 'yaml'

# Test Config Manager
class ConfigManagerTest < Test::Unit::TestCase
  def setup
    @config_file = './lib/config.yml'
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
