# Copyright (c) 2023 ENEO Tecnologia S.L.
# This file is part of redBorder.
# # redBorder is free software: you can redistribute it and/or modify
# # it under the terms of the GNU Affero General Public License as published by
# # the Free Software Foundation, either version 3 of the License, or
# # (at your option) any later version.
# # redBorder is distributed in the hope that it will be useful,
# # but WITHOUT ANY WARRANTY; without even the implied warranty of
# # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# # GNU Affero General Public License for more details.
# # You should have received a copy of the GNU Affero General Public License
# # along with redBorder. If not, see <http://www.gnu.org/licenses/>.
# #######################################################################
#

require 'logger'
require_relative './aruba_config'

# Module for manage aruba logs
module ArubaLogger
  # Main class to manage and process aruba logs
  class LogController
    attr_accessor :logger, :log_level, :log_name, :last_log

    def initialize(log_name, log_level = Logger::WARN)
      @color_escape = {
        blue: 34,
        red: 31,
        green: 32
      }
      @last_log = ''
      @log_name = log_name
      @log_level = log_level
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
        "module=[#{@log_name}] date=[#{date_format}] severity=#{severity.ljust(5)} pid=##{Process.pid} message=#{msg}\n"
      end
    end

    def c(clr, text = nil)
      "\x1B[" + (@color_escape[clr] || 0).to_s + 'm' + (text ? text + "\x1B[0m" : '')
    end

    def debug(message)
      @last_log = message
      @logger.debug(c(:blue, message)) if @log_level >= 3
    end

    def error(message)
      @last_log = message
      @logger.error(c(:red, message))
    end

    def info(message)
      @last_log = message
      @logger.info(c(:green, message)) if @log_level >= 2
    end
  end
end
