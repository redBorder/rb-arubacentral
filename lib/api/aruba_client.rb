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
require_relative '../helpers/aruba_cache'
require 'net/http'
require 'time'
require 'json'

# Aruba REST implementation in ruby
module ArubaREST
  # Aruba REST Client implementation for ruby
  class Client # rubocop:disable Metrics/ClassLength
    attr_accessor :gateway, :username, :password, :client_id, :client_secret, :client_customer_id, :cache, :self_token

    def initialize(gateway, username, password, client_id, client_secret, client_customer_id, cache, log_level)
      @gateway = gateway
      @username = username
      @password = password
      @client_id = client_id
      @client_secret = client_secret
      @client_customer_id = client_customer_id
      @cache_ttl = cache['ttl']
      @cache_keys = cache['keys']
      @connections = {}
      @aps = {}
      @cache = ArubaCache.new
      @log_controller = ArubaLogger::LogController.new(
        'ArubaREST',
        log_level
      )
      refresh_oauth_token
    end

    def refresh_oauth_token
      @log_controller.info('Refreshing oauth_token...')
      @self_token = OAuthHelper.oauth(
        @gateway,
        @username,
        @password,
        @client_id,
        @client_secret,
        @client_customer_id
      )['access_token']
    end

    def make_api_request(api_endpoint)
      @log_controller.debug("Requesting data from #{api_endpoint}")
      begin
        uri = URI.join(@gateway, api_endpoint)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        # http.use_ssl = false
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.read_timeout = 30
        http.open_timeout = 10

        request = Net::HTTP::Get.new(uri.request_uri)
        request['Authorization'] = "Bearer #{@self_token}"
        request['Content-Type'] = 'application/json'
        @log_controller.debug("Making request to..#{api_endpoint}")
        response = http.request(request)
        @log_controller.debug('Request finished')
        response
      rescue Net::ReadTimeout
        @log_controller.error("Timeout while waiting for a response from #{api_endpoint}")
        nil
      rescue Net::OpenTimeout
        @log_controller.error("Timeout while waiting for opening request #{api_endpoint}")
        nil
      rescue StandardError => e
        @log_controller.error("An unexpected error occurred: #{e.message}")
        nil
      end
    end

    def fetch_data(api_endpoint, cache_name)
      cache_key = "api_response:#{api_endpoint}"
      cache = @cache_keys.include? cache_name
      cache_refresh = begin
        @cache_ttl[cache_name.to_sym].to_i
      rescue StandardError
        0
      end
      @log_controller.debug("fetch data from #{cache_key}, cached[#{cache}], cache_refresh_ttl[#{cache_refresh}]")
      @cache.fetch(cache_key, cache_refresh, cache) do
        response = make_api_request(api_endpoint)
        return {} unless response

        data = {}
        @log_controller.debug("Response status code is #{response.code}")

        case response.code
        when '200'
          data = JSON.parse(response.body)
        when '401'
          @log_controller.debug('401, refreshing token')
          refresh_oauth_token
          response = make_api_request(api_endpoint)
          @log_controller.debug('Re-requesting data...')
          data = JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
        end

        data
      end
    end

    def update_ap_status(mac_add, ap_status)
      @aps[mac_add.downcase] = ap_status
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

    def fetch_wireless_clients
      data = {}
      data['clients'] = []
      offset = 0
      wireless_clients_size = 100
      while wireless_clients_size == 100
        wireless_clients = fetch_data("/monitoring/v1/clients/wireless?offset=#{offset}", __method__.to_s)
        wireless_clients_size = wireless_clients.size
        # TODO: only keep data used (macaddr, associated_device_mac)
        data['clients'] += wireless_clients['clients']
        offset += 1
      end
      data
    end

    def fetch_ap_status
      fetch_data('/monitoring/v2/aps', __method__.to_s)
    end

    def fetch_ap_top
      data = {
        floors: [],
        aps: [],
        aps_info: {}
      }

      campuses = fetch_all_campuses
      @log_controller.debug("Campus data #{campuses}")
      if campuses.key?('campus')
        campuses['campus'].each do |campus|
          campus_info = fetch_campus(campus['campus_id'])
          @log_controller.debug("Campus info for #{campus['campus_id']} -> #{campus_info}")
          campus_info['buildings']

          next unless campus_info.key?('buildings')

          campus_info['buildings'].each do |building|
            building_info = fetch_building(building['building_id'])
            @log_controller.debug("Building info #{building_info}")
            floors = building_info['floors']

            data[:floors].push(floors)
            next unless building_info.key?('floors')

            building_info['floors'].each do |floor|
              aps = fetch_aps(floor['floor_id'])
              @log_controller.debug("Aps info #{aps}")
              data[:aps].push(aps)

              aps['access_points'].each do |ap|
                ap_info = {
                  'floor' => floor['floor_name'],
                  'building' => building['building_name'],
                  'campus' => campus['campus_name'],
                  'name' => ap['ap_name'],
                  'reference_lat' => building['latitude'],
                  'reference_lon' => building['longitude']
                }

                data[:aps_info][ap['ap_eth_mac'].downcase] = ap_info
              end
            end
          end
        end
      end
      data
    end

    def find_closest_ap(data, xpos, ypos)
      closest_ap = nil
      closest_distance = nil
      data[:aps].each do |aps|
        aps['access_points'].each do |ap|
          next unless @aps[ap['ap_eth_mac'].downcase] == 'Up'
          
          ap_x = ap['x']
          ap_y = ap['y']
          distance = ArubaMathHelper.calculate_distance(xpos, ypos, ap_x, ap_y)

          if closest_distance.nil? || distance < closest_distance
            closest_ap = ap
            closest_distance = distance
          end
        end
      end
      closest_ap
    end

    def find_associated_device_mac(data, macaddr_to_find)
      @log_controller.debug("Finding associated device mac for #{macaddr_to_find}")
      if data && data['clients'].is_a?(Array)
        data['clients'].each do |client|
          return client['associated_device_mac'] if client['macaddr'] == macaddr_to_find
        end
      end
      nil
    end

    def find_ap_info(top, ap_mac, client_real_x, client_real_y)
      @log_controller.debug("Finding AP info for #{ap_mac}, x: #{client_real_x}, y: #{client_real_y}")
      ap_info = top[:aps_info][ap_mac.downcase]
      ap_info = top[:aps_info][find_closest_ap(top, client_real_x, client_real_y)['ap_eth_mac'].downcase] if ap_info.nil?
      ap_info
    end

    def find_ap_mac(is_client_associated, clients, client_mac_address, top, client_real_x, client_real_y)
      if is_client_associated
        find_associated_device_mac(clients, client_mac_address) || find_closest_ap(top, client_real_x, client_real_y)['ap_eth_mac']
      else
        find_closest_ap(top, client_real_x, client_real_y)['ap_eth_mac']
      end
    end

    def process_floor_location_data(floor_location, clients, top)
      data = []
      floor_location['locations'].each do |client|
        client_real_x = client['x']
        client_real_y = client['y']
        client_mac_address = client['device_mac']
        is_client_associated = client['associated']

        ap_mac = find_ap_mac(is_client_associated, clients, client_mac_address, top, client_real_x, client_real_y)

        @log_controller.debug("AP mac found -> #{ap_mac}")

        @connections[ap_mac] ||= 0
        @connections[ap_mac] += 1 if is_client_associated

        @log_controller.debug("Connections for #{ap_mac} are -> #{@connections[ap_mac]}")

        ap_info = find_ap_info(top, ap_mac, client_real_x, client_real_y)

        client_real_lat, client_real_lon = ArubaMathHelper.move_coordinates_meters(client_real_x, -client_real_y, ap_info['reference_lat'], ap_info['reference_lon'])

        data << {
          lat: client_real_lat,
          long: client_real_lon,
          client_mac_address: client_mac_address,
          ap_mac_address: ap_mac,
          topology: "#{ap_info['campus']}>#{ap_info['building']}>#{ap_info['floor']}",
          associated: is_client_associated,
          time: Time.now.utc.round(4).iso8601(3).to_s
        }
      end
      data
    end

    def fetch_location_production_data
      @log_controller.info('Calculating location data...')
      top = fetch_ap_top
      clients = fetch_wireless_clients
      @connections = {}
      data_to_produce = []

      top[:floors].each do |floor|
        floor.each do |floor_data|
          floor_id = floor_data['floor_id']
          offset = 0
          floor_location_size = 100
          while floor_location_size == 100
            floor_location = fetch_floor_location(floor_id, offset)
            floor_location_size = floor_location['locations'].size
            data_to_produce += process_floor_location_data(floor_location, clients, top)
            offset += 1
          end
        end
      end
      data_to_produce
    end

    def fetch_ap_status_production_data
      @log_controller.info('Calculating APs statuses...')
      access_points = []
      data = fetch_ap_status

      data['aps'].each do |ap|
        access_points << {
          ap_mac_address: ap['macaddr'],
          ap_status: ap['status'] == 'Up' ? 'on' : 'off',
          ap_client_count: @connections[ap['macaddr']].instance_of?(NilClass) ? 0 : @connections[ap['macaddr']]
        }
        update_ap_status(ap['macaddr'], ap['status'])
      end
      access_points
    end
  end
end
