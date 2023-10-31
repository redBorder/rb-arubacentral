#!/usr/bin/env ruby

require 'getopt/std'

require_relative './api/aruba_client'
require_relative './helpers/aruba_config'
require_relative './kafka/producer.rb'

CONFIG_FILE_PATH = 'config.yml'.freeze
aruba_central_sensors = []

opt = Getopt::Std.getopts('hc:')
config_file = !opt['c'].nil? ? opt['c'] : CONFIG_FILE_PATH

config = ConfigManager.load_config(config_file)

sensors = config['sensors']

sensors.each do |sensor|
  aruba_central = ArubaREST::Client.new(
    sensor['gateway'],
    sensor['email'],
    sensor['password'],
    sensor['client_id'],
    sensor['client_secret'],
    sensor['customer_id']
  )
  aruba_central_sensors.push(aruba_central)
end

producer = Kafka::Producer.new(
  config['kafka']['broker'],
  config['kafka']['producer_name']
)

generator = Kafka::EventGenerator.new

loop do
  aruba_central_sensors.each do |aruba_central_sensor|
    begin
      location_data = generator.location_from_multiple_messages(aruba_central_sensor.fetch_location_production_data)
      status_data = generator.status_from_multiple_messages(aruba_central_sensor.fetch_ap_status_production_data)
      producer.send_kafka_multiple_msgs(location_data, config['kafka']['location_topic'])
      producer.send_kafka_multiple_msgs(status_data, config['kafka']['status_topic'])
    rescue StandardError
      puts "Something went wrong in sensor #{aruba_central_sensor}"
    end
  end
  sleep(config['service']['sleep_time'])
end
