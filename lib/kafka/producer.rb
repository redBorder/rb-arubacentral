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

require 'poseidon'
require 'time'
require_relative '../helpers/aruba_logger'

module Kafka
  # Class to produce kafka messages to the destination kafka broker
  class Producer
    def initialize(host, producer_name, log_level)
      @host = host
      @producer_name = producer_name
      @producer = Poseidon::Producer.new([@host], @producer_name)
      @log_controller = ArubaLogger::LogController.new(
        'Kafka',
        log_level
      )
    end

    def send_to_kafka(msg, topic)
      messages = []
      messages << Poseidon::MessageToSend.new(topic, msg.to_json)
      @producer.send_messages(messages)
    rescue StandardError => e
      @log_controller.error("Error producing messages to kafka #{topic} : #{e.message}")
    end

    def send_kafka_multiple_msgs(msgs, topic = 'rb_loc')
      @log_controller.info('Producing data to kafka...')
      msgs.each do |msg|
        @log_controller.debug("Producing msg to kafka -> #{msg} to topic -> #{topic}")
        send_to_kafka(msg, topic)
      end
    end
  end

  # Class to Generate kafka messages from the source data
  class EventGenerator
    def initialize(log_level, mac_to_sensoruuid = {})
      @log_controller = ArubaLogger::LogController.new(
        'Event Generator',
        log_level
      )
      @mac_to_sensoruuid = mac_to_sensoruuid
    end

    def location_from_multiple_messages(data)
      result = []

      data.each do |item|
        json_message = {
          'StreamingNotification' => {
            'subscriptionName' => 'WLC',
            'location' => {
              'macAddress' => item[:client_mac_address].downcase,
              'mapInfo' => {
                'mapHierarchyString' => item[:topology]
              },
              'geoCoordinate' => {
                'lattitude' => item[:lat],
                'longitude' => item[:long]
              },
              'apMacAddress' => item[:ap_mac_address].downcase,
              'dot11Status' => item[:associated] ? 'ASSOCIATED' : 'PROBING'
            },
            'timestamp' => item[:time]
          }
        }

        result << json_message
      end

      @log_controller.debug("location data is -> #{result}")

      result
    end

    def status_from_multiple_messages(data)
      result = []
      data.each do |item|
        json_message = {
          'wireless_station' => item[:ap_mac_address].downcase,
          'type' => 'snmp_apMonitor',
          'client_count' => item[:ap_client_count],
          'timestamp' => Time.now.to_i,
          'status' => item[:ap_status]
        }
        json_message['sensor_uuid'] = @mac_to_sensoruuid[item[:ap_mac_address].downcase] if @mac_to_sensoruuid.key?(item[:ap_mac_address].downcase)
        @log_controller.debug("status data is -> #{result}")

        result << json_message
      end

      result
    end
  end
end
