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

Dir["../helpers/*.rb"].each {|file| require_relative file }

module ArubaREST
  class Client
    include ArubaBuilder
    include ArubaMathHelper
    include ArubaLogger
    include ArubaDataProcessor
    include OAuthHelper
    include ArubaAuthRefresher

    ENDPOINT = {
      all_campuses: '/visualrf_api/v1/campus',
      campus: '/visualrf_api/v1/campus/%<campus_id>s',
      floor_location: '/visualrf_api/v1/floor/%<floor_id>s/client_location?offset=%<offset>d&limit=%<limit>d',
      building: '/visualrf_api/v1/building/%<building_id>s',
      aps: '/visualrf_api/v1/floor/%<floor_id>s/access_point_location',
      ap_status: '/monitoring/v2/aps'
    }.freeze

    attr_accessor :gateway, :credentials, :cache, :self_token

    def initialize(gateway, credentials, cache_config, log_level)
      @gateway = gateway
      @log_level = log_level
      init_credentials(credentials)
      init_log_controller
      init_cache(cache_config)
      init_structures
      refresh_oauth_token
    end

    def fetch_all_campuses
      fetch_data(ENDPOINT[:all_campuses])
    end

    def fetch_campus(campus_id)
      endpoint = ENDPOINT[:campus] % { campus_id: campus_id }
      fetch_data(endpoint)
    end

    def fetch_floor_location(floor_id, offset = 0, limit = 100)
      endpoint = ENDPOINT[:floor_location] % { floor_id: floor_id, offset: offset, limit: limit }
      fetch_data(endpoint)
    end

    def fetch_building(building_id)
      endpoint = ENDPOINT[:building] % { building_id: building_id }
      fetch_data(endpoint)
    end

    def fetch_aps(floor_id)
      endpoint = ENDPOINT[:aps] % { floor_id: floor_id }
      fetch_data(endpoint)
    end

    def fetch_ap_status
      fetch_data(ENDPOINT[:ap_status])
    end

    private

    def init_credentials(credentials)
      @username = credentials.username
      @password = credentials.password
      @client_id = credentials.client_id
      @client_secret = credentials.client_secret
      @client_customer_id = credentials.client_customer_id
    end

    def init_log_controller
      @log_controller = LogController.new(name, @log_level)
    end

    def init_cache(cache_config)
      @cache_ttl = cache_config['ttl']
      @cache_keys = cache_config['keys']
      @cache = EasyCache.new
    end

    def init_structures
      @connections = {}
      @aps = {}
    end
  end
end
