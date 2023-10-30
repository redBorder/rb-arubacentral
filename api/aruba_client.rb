require_relative '../helpers/aruba_oauth'
require_relative '../helpers/aruba_math'
require 'net/http'
require 'time'
require 'json'

# Aruba REST implementation in ruby
module ArubaREST
  # Aruba REST Client implementation for ruby
  class Client
    attr_accessor :self_token, :gateway, :username, :password, :client_id, :client_secret, :client_customer_id, :connections

    def initialize(gateway, username, password, client_id, client_secret, client_customer_id)
      @gateway = gateway
      @username = username
      @password = password
      @client_id = client_id
      @client_secret = client_secret
      @client_customer_id = client_customer_id
      @connections = {}
      refresh_oauth_token
    end

    def refresh_oauth_token
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
      uri = URI.join(@gateway, api_endpoint)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Authorization'] = "Bearer #{@self_token}"
      request['Content-Type'] = 'application/json'
      http.request(request)
    end

    def fetch_data(api_endpoint)
      response = make_api_request(api_endpoint)

      data = {}
      case response.code
      when '200'
        data = JSON.parse(response.body)
      when '401'
        refresh_oauth_token
        response = make_api_request(api_endpoint)
        data = JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
      end
      data
    end

    def fetch_all_campuses
      fetch_data('/visualrf_api/v1/campus')
    end

    def fetch_campus(campus_id)
      fetch_data('/visualrf_api/v1/campus/' + campus_id)
    end

    def fetch_floor_location(floor_id)
      fetch_data('/visualrf_api/v1/floor/' + floor_id + '/client_location')
    end

    def fetch_building(building_id)
      fetch_data('/visualrf_api/v1/building/' + building_id)
    end

    def fetch_aps(floor_id)
      fetch_data('/visualrf_api/v1/floor/' + floor_id + '/access_point_location')
    end

    def fetch_wireless_clients
      fetch_data('/monitoring/v1/clients/wireless')
    end

    def fetch_ap_status
      fetch_data('/monitoring/v2/aps')
    end

    def fetch_ap_top
      data = {
        floors: [],
        aps: [],
        aps_info: {}
      }

      campuses = fetch_all_campuses

      campuses['campus'].each do |campus|
        campus_info = fetch_campus(campus['campus_id'])
        buildings = campus_info['buildings']

        buildings.each do |building|
          building_info = fetch_building(building['building_id'])
          floors = building_info['floors']

          data[:floors].push(floors)

          floors.each do |floor|
            aps = fetch_aps(floor['floor_id'])
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

      data
    end

    def find_closest_ap(data, xpos, ypos)
      closest_ap = nil
      closest_distance = nil
      data[:aps].each do |aps|
        aps['access_points'].each do |ap|
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
      if data && data['clients'].is_a?(Array)
        data['clients'].each do |client|
          return client['associated_device_mac'] if client['macaddr'] == macaddr_to_find
        end
      end
      nil
    end

    def fetch_location_production_data
      top = fetch_ap_top
      clients = fetch_wireless_clients
      @connections = {}
      data_to_produce = []

      top[:floors].each do |floor|
        floor.each do |floor_data|
          floor_id = floor_data['floor_id']
          floor_location = fetch_floor_location(floor_id)

          floor_location['locations'].each do |client|
            client_real_x = client['x']
            client_real_y = client['y']
            client_mac_address = client['device_mac']
            is_client_associated = client['associated']

            ap_mac = if is_client_associated
                       find_associated_device_mac(clients, client_mac_address) || find_closest_ap(top, client_real_x, client_real_y)['ap_eth_mac']
                     else
                       find_closest_ap(top, client_real_x, client_real_y)['ap_eth_mac']
                     end

            @connections[ap_mac] ||= 0
            @connections[ap_mac] += 1 if is_client_associated

            ap_info = top[:aps_info][ap_mac.downcase]

            client_real_lat, client_real_lon = ArubaMathHelper.move_coordinates_meters(client_real_x, -client_real_y, ap_info['reference_lat'], ap_info['reference_lon'])

            data_to_produce << {
              lat: client_real_lat,
              long: client_real_lon,
              client_mac_address: client_mac_address,
              ap_mac_address: ap_mac,
              topology: "#{ap_info['campus']}>#{ap_info['building']}>#{ap_info['floor']}",
              associated: is_client_associated,
              time: Time.now.utc.round(4).iso8601(3).to_s
            }
          end
        end
      end

      data_to_produce
    end

    def fetch_ap_status_production_data
      access_points = []
      data = fetch_ap_status

      data['aps'].each do |ap|
        access_points << {
          ap_mac_address: ap['macaddr'],
          ap_status: ap['status'] == 'Up' ? 'on' : 'off',
          ap_client_count: @connections[ap['macaddr']].class == NilClass ? 0 : @connections[ap['macaddr']]
        }
      end
      access_points
    end
  end
end
