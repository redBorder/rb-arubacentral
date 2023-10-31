require_relative './helpers/codecov_helper.rb'
require_relative '../lib/kafka/producer.rb'
require 'test/unit'

# Test Kafka Event Generator
class EventGeneratorTest < Test::Unit::TestCase
  def setup
    @event_generator = Kafka::EventGenerator.new
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
        'status' => 'on'
      },
      {
        'wireless_station' => '00:00:00:00:01',
        'type' => 'snmp_apMonitor',
        'client_count' => 10,
        'timestamp' => Time.now.to_i,
        'status' => 'off'
      }
    ]
    actual_result = @event_generator.status_from_multiple_messages(data)

    assert_equal expected_result, actual_result
  end
end
