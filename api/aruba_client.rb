require_relative '../helpers/aruba_oauth'
require_relative '../helpers/aruba_math'
require 'net/http'
require 'time'
require 'json'

module ArubaREST
  class Client
    attr_accessor :self_token, :gateway, :username, :password, :client_id, :client_secret, :client_customer_id, :base_url

    def initialize(gateway, username, password, client_id, client_secret, client_customer_id, base_url)
      @gateway = gateway
      @username = username
      @password = password
      @client_id = client_id
      @client_secret = client_secret
      @client_customer_id = client_customer_id
      @base_url = base_url
      refresh_oauth_token()
    end

    def refresh_oauth_token
      @self_token = OAuthHelper.oauth(
        @gateway,
        @username,
        @password,
        @client_id,
        @client_secret,
        @client_customer_id
      )["access_token"]
    end

    def make_api_request(api_endpoint)
      puts @base_url
      puts api_endpoint
      puts @self_token
      uri = URI.join(@base_url, api_endpoint)
      http = Net::HTTP.new(uri.host, uri.port)
      puts uri.host, uri.request_uri
      http.use_ssl = (uri.scheme == 'https')
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Authorization'] = "Bearer #{@self_token}"
      request['Content-Type'] = 'application/json'
      http.request(request)
    end

    def get_data(api_endpoint)
      response = self.make_api_request(api_endpoint)
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        data
      else
        puts "API request failed with status code: #{response.code}"
        puts "Response body: #{response.body}"
        {}
      end
    end

    def get_all_campuses
      self.get_data('/visualrf_api/v1/campus')
    end

    def get_campus(campus_id)
      self.get_data('/visualrf_api/v1/campus/' + campus_id)
    end

    def get_floor_location(floor_id)
      self.get_data('/visualrf_api/v1/floor/' + floor_id + '/client_location')
    end

    def get_building(building_id)
      self.get_data('/visualrf_api/v1/building/' + building_id)
    end

    def get_aps(floor_id)
      self.get_data('/visualrf_api/v1/floor/' + floor_id + '/access_point_location')
    end

    def get_wireless_clients
      self.get_data("/monitoring/v1/clients/wireless")
    end

    def get_ap_top
      data = {
        floors: [],
        aps: [],
        aps_info: {}
      }

      campuses = get_all_campuses

      campuses["campus"].each do |campus|
        campus_info = get_campus(campus["campus_id"])
        buildings = campus_info["buildings"]

        buildings.each do |building|
          building_info = get_building(building["building_id"])
          floors = building_info["floors"]

          data[:floors].push(floors)

          floors.each do |floor|
            aps = get_aps(floor["floor_id"])
            data[:aps].push(aps)

            aps["access_points"].each do |ap|
              ap_info = {
                "floor" => floor["floor_name"],
                "building" => building["building_name"],
                "campus" => campus["campus_name"],
                "name" => ap["ap_name"],
                "reference_lat" => building["latitude"],
                "reference_lon" => building["longitude"]
              }

              data[:aps_info][ap["ap_eth_mac"].downcase] = ap_info
            end
          end
        end
      end

      data
    end

    def find_closest_ap(data, x, y)
      closest_ap = nil
      closest_distance = nil
      data[:aps].each do |aps|
        aps["access_points"].each do |ap|
          ap_x = ap["x"]
          ap_y = ap["y"]
          distance = ArubaMathHelper.calculate_distance(x, y, ap_x, ap_y)

          if closest_distance.nil? || distance < closest_distance
            closest_ap = ap
            closest_distance = distance
          end
        end
      end
      closest_ap
    end

    def find_associated_device_mac(data, macaddr_to_find)
        if data && data["clients"].is_a?(Array)
            data["clients"].each do |client|
                if client["macaddr"] == macaddr_to_find
                    return client["associated_device_mac"]
                end
            end
        end
        nil
    end

    def fetch_production_data
      top = get_ap_top
      clients = get_wireless_clients

      data_to_produce = []

      top[:floors].each do |floor|
        floor.each do |floor_data|
          floor_id = floor_data["floor_id"]
          floor_location = get_floor_location(floor_id)

          floor_location['locations'].each do |client|
            client_real_x, client_real_y, client_mac_address, is_client_associated = client['x'], client['y'], client['device_mac'], client['associated']

            ap_mac = if is_client_associated
                        find_associated_device_mac(clients, client_mac_address) || find_closest_ap(top, client_real_x, client_real_y)['ap_eth_mac']
                      else
                        find_closest_ap(top, client_real_x, client_real_y)['ap_eth_mac']
                      end

            ap_info = top[:aps_info][ap_mac.downcase]

            client_real_lat, client_real_lon = ArubaMathHelper.move_coordinates_meters(client_real_x, -client_real_y, ap_info["reference_lat"], ap_info["reference_lon"])

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
  end
end