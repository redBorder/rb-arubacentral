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
# Class for post-process data fetched from the REST API
#
class ArubaPostProcessor
  def fetch_location_production_data
    @log_controller.info('Calculating location data...')
    top = fetch_ap_top
    clients = fetch_wireless_clients
    @connections = {}

    top[:floors].flat_map do |floor|
      floor.flat_map do |floor_data|
        process_floor_data(top, clients, floor_data['floor_id'], 0)
      end
    end
  end

  def fetch_ap_status_production_data
    @log_controller.info('Calculating APs statuses...')
    fetch_ap_status['aps'].map { |ap| process_ap_data(ap) }
  end

  private

  def process_floor_data(top, clients, floor_id, offset)
    floor_location_size = 100
    [].tap do |data_to_produce|
      while floor_location_size == 100
        floor_location = fetch_floor_location(floor_id, offset)
        floor_location_size = floor_location['locations'].size
        data_to_produce.concat(process_floor_location_data(floor_location, clients, top))
        offset += 1
      end
    end
  end

  def process_ap_data(access_point)
    ap_status = access_point['status'] == 'Up' ? 'on' : 'off'
    ap_client_count = @connections.fetch(access_point['macaddr'], 0)
    {
      ap_mac_address: access_point['macaddr'],
      ap_status: ap_status,
      ap_client_count: ap_client_count
    }.tap { update_ap_status(access_point['macaddr'], access_point['status']) }
  end
end
