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

#
# Class to process data fetched from the REST API
#
class ArubaDataProcessor
  def update_ap_status(mac_address, ap_status)
    @aps[mac_address.downcase] = ap_status
  end

  def fetch_wireless_clients
    data = { 'clients' => [] }
    offset = 0
    wireless_clients_size = 100
    while wireless_clients_size == 100
      wireless_clients = fetch_data("/monitoring/v1/clients/wireless?offset=#{offset}", __method__.to_s)
      data['clients'] += wireless_clients['clients']
      offset += 1
      wireless_clients_size = wireless_clients.size
    end
    data
  end

  def fetch_ap_top
    data = initialize_data_structure
    campuses = fetch_all_campuses
    campuses['campus']&.each do |campus|
      process_campus(campus, data)
    end
    data
  end

  def find_ap_based_on_mac(data, mac)
    data[:aps].each do |aps|
      aps['access_points']&.each do |ap|
        return [data[:aps_info][ap['ap_eth_mac'].downcase], ap] if ap['ap_eth_mac'].downcase == mac
      end
    end
    nil
  end

  private

  def initialize_data_structure
    { floors: [], aps: [], aps_info: {} }
  end

  def process_campus(campus, data)
    campus_info = fetch_campus(campus['campus_id'])
    return unless campus_info.key?('buildings')

    campus_info['buildings'].each do |building|
      process_building(building, data)
    end
  end

  def process_building(building, data)
    floors = building['floors']
    data[:floors].push(floors)
    return unless (building_info = fetch_building(building['building_id']))

    building_info['floors']&.each do |floor|
      process_floor(floor, data)
    end
  end

  def process_floor(floor, data)
    aps = fetch_aps(floor['floor_id'])
    data[:aps].push(aps)

    aps['access_points']&.each do |ap|
      process_access_point(ap, floor, data)
    end
  end

  def process_access_point(access_point, floor, data)
    ap_info = build_ap_info(access_point, floor)
    data[:aps_info][access_point['ap_eth_mac'].downcase] = ap_info
  end

  def build_ap_info(access_point, floor)
    {
      'floor' => floor['floor_name'],
      'building' => building['building_name'],
      'campus' => campus['campus_name'],
      'name' => access_point['ap_name'],
      'reference_lat' => building['latitude'],
      'reference_lon' => building['longitude']
    }
  end
end
