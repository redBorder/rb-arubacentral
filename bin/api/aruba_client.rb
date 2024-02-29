# frozen_string_literal: true

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

require_relative '../helpers/aruba_oauth'
require_relative '../helpers/aruba_math'
require_relative '../helpers/aruba_logger'
require_relative '../helpers/aruba_builder'
require_relative '../helpers/aruba_data_processor'
require_relative '../helpers/aruba_http'
require 'easycache'
require 'net/http'
require 'time'
require 'json'

# Aruba REST implementation in ruby
module ArubaREST
  # Aruba REST Client implementation for ruby
  class Client
    include ArubaBuilder
    include ArubaMathHelper
    include ArubaLogger
    include ArubaDataProcessor
    include OAuthHelper
    include ArubaAuthRefresher
    attr_accessor :gateway, :credentials, :cache, :self_token

    def initialize(gateway, credentials, _cache, log_level)
      init_gw(gateway)
      init_log_controller(log_level)
      init_credentials(credentials)
      init_structures
      init_cache
      refresh_oauth_token
    end

    def fetch_all_campuses
      fetch_data('/visualrf_api/v1/campus', __method__.to_s)
    end

    def fetch_campus(campus_id)
      fetch_data("/visualrf_api/v1/campus/#{campus_id}", __method__.to_s)
    end

    def fetch_floor_location(floor_id, offset = 0, limit = 100)
      fetch_data("/visualrf_api/v1/floor/#{floor_id}/client_location?offset=#{offset}&limit=#{limit}", __method__.to_s)
    end

    def fetch_building(building_id)
      fetch_data("/visualrf_api/v1/building/#{building_id}", __method__.to_s)
    end

    def fetch_aps(floor_id)
      fetch_data("/visualrf_api/v1/floor/#{floor_id}/access_point_location", __method__.to_s)
    end

    def fetch_ap_status
      fetch_data('/monitoring/v2/aps', __method__.to_s)
    end

    def init_gw(gateway)
      @gateway = gateway
    end

    private

    def init_credentials(credentials)
      @username = credentials[:username]
      @password = credentials[:password]
      @client_id = credentials[:client_id]
      @client_secret = credentials[:client_secret]
      @client_customer_id = credentials[:client_customer_id]
    end

    def init_log_controller
      @log_controller = LogController.new(name, log_level)
    end

    def init_cache
      @cache_ttl = cache['ttl']
      @cache_keys = cache['keys']
      @cache = EasyCache.new
    end

    def init_structures
      @connections = {}
      @aps = {}
    end
  end
end
