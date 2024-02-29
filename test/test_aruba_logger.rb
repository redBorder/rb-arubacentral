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
require_relative '../bin/helpers/aruba_logger'
require 'test/unit'

# Test Logger Helpers
class ArubaLoggerHelperTest < Test::Unit::TestCase
  def setup
    @logger = ArubaLogger::LogController.new('test_logger', 3)
  end

  def test_initialize_with_valid_args
    assert_equal 'test_logger', @logger.log_name
    assert_equal 3, @logger.log_level
  end

  def test_initialize_with_invalid_log_level
    assert_raises(ArgumentError) do
      ArubaLogger::LogController.new
    end
  end

  def test_debug_logs_message_with_blue_color
    @logger.debug('This is a debug message')
    assert_match 'This is a debug message', @logger.last_log
  end

  def test_error_logs_message_with_red_color
    @logger.error('This is an error message')
    assert_match 'This is an error message', @logger.last_log
  end

  def test_info_logs_message_with_green_color
    @logger.info('This is an info message')
    assert_match 'This is an info message', @logger.last_log
  end
end
