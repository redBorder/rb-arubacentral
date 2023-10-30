#!/usr/bin/env ruby

require 'getopt/std'

require_relative './api/aruba_client'
require_relative './helpers/aruba_config'
require_relative './kafka/producer.rb'

CONFIG_FILE_PATH = 'config.yml'
aruba_central_sensors=[]

opt = Getopt::Std.getopts("hc:")
!opt["c"].nil? ? config_file = opt["c"] : config_file = CONFIG_FILE_PATH

config = ConfigManager.load_config(config_file)

sensors = config["sensors"]

sensors.each do |sensor|
    aruba_central = ArubaREST::Client.new(
        sensor["gateway"],
        sensor["email"],
        sensor["password"],
        sensor["client_id"],
        sensor["client_secret"],
        sensor["customer_id"],
        sensor["base_url"]
    )
    aruba_central_sensors.push(aruba_central)
end

producer = Kafka::Producer.new(
    config["kafka"]["broker"],
    config["kafka"]["producer_name"],
    config["kafka"]["topic"]
)

generator = Kafka::EventGenerator.new()

while true do
    aruba_central_sensors.each do |aruba_central_sensor|
      data = generator.from_multiple_messages(aruba_central_sensor.fetch_production_data())
      producer.send_kafka_multiple_msgs(data)
    end
    sleep(config["service"]["sleep_time"])
end
