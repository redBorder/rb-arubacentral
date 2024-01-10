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
require_relative '../lib/kafka/producer'
require 'test/unit'

# Test Kafka Event Generator
class EventGeneratorTest < Test::Unit::TestCase
  def setup
    @event_generator = Kafka::EventGenerator.new(0, { '00:00:00:00:00' => '74d81444-0589-4746-b189-7263667834ed', '00:00:00:00:01' => '74d81444-0589-4746-b189-7263667834ed' })
  end

  def test_location_from_multiple_messages
    data = [
      {
        client_mac_address: '00:11:22:33:44:55',
        topology: '/root/site1/building1/floor1',
        lat: 37.7833,
        long: -122.4167,
        ap_mac_address: 'aa:bb:cc:dd:ee:ff',
        associated: true,
        time: Time.now.to_i
      },
      {
        client_mac_address: '66:77:88:99:aa:bb',
        topology: '/root/site2/building2/floor2',
        lat: -33.8667,
        long: 151.2000,
        ap_mac_address: 'ff:ee:dd:cc:bb:aa',
        associated: false,
        time: Time.now.to_i
      }
    ]

    expected_result = [
      {
        'StreamingNotification' => {
          'subscriptionName' => 'WLC',
          'location' => {
            'macAddress' => '00:11:22:33:44:55',
            'mapInfo' => {
              'mapHierarchyString' => '/root/site1/building1/floor1'
            },
            'geoCoordinate' => {
              'lattitude' => 37.7833,
              'longitude' => -122.4167
            },
            'apMacAddress' => 'aa:bb:cc:dd:ee:ff',
            'dot11Status' => 'ASSOCIATED'
          },
          'timestamp' => data[0][:time]
        }
      },
      {
        'StreamingNotification' => {
          'subscriptionName' => 'WLC',
          'location' => {
            'macAddress' => '66:77:88:99:aa:bb',
            'mapInfo' => {
              'mapHierarchyString' => '/root/site2/building2/floor2'
            },
            'geoCoordinate' => {
              'lattitude' => -33.8667,
              'longitude' => 151.2000
            },
            'apMacAddress' => 'ff:ee:dd:cc:bb:aa',
            'dot11Status' => 'PROBING'
          },
          'timestamp' => data[1][:time]
        }
      }
    ]

    actual_result = @event_generator.location_from_multiple_messages(data)

    assert_equal expected_result, actual_result
  end

  def test_status_from_multiple_messages
    data = [
      {
        ap_mac_address: '00:00:00:00:00',
        ap_client_count: 0,
        ap_status: 'on'
      },
      {
        ap_mac_address: '00:00:00:00:01',
        ap_client_count: 10,
        ap_status: 'off'
      }
    ]

    expected_result = [
      {
        'wireless_station' => '00:00:00:00:00',
        'type' => 'snmp_apMonitor',
        'client_count' => 0,
        'timestamp' => Time.now.to_i,
        'status' => 'on',
        'sensor_uuid' => '74d81444-0589-4746-b189-7263667834ed'
      },
      {
        'wireless_station' => '00:00:00:00:01',
        'type' => 'snmp_apMonitor',
        'client_count' => 10,
        'timestamp' => Time.now.to_i,
        'status' => 'off',
        'sensor_uuid' => '74d81444-0589-4746-b189-7263667834ed'
      }
    ]
    actual_result = @event_generator.status_from_multiple_messages(data)

    assert_equal expected_result, actual_result
  end
end
