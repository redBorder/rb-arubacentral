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

require 'getopt/std'

require_relative './api/aruba_client'
require_relative './helpers/aruba_config'
require_relative './helpers/aruba_logger'
require_relative './kafka/producer.rb'

CONFIG_FILE_PATH = 'config.yml'.freeze
aruba_central_sensors = []

opt = Getopt::Std.getopts('hc:')
config_file = !opt['c'].nil? ? opt['c'] : CONFIG_FILE_PATH

config = ConfigManager.load_config(config_file)

sensors = config['sensors']

log_level = config['service']['log_level']

sensors.each do |sensor|
  aruba_central = ArubaREST::Client.new(
    sensor['gateway'],
    sensor['email'],
    sensor['password'],
    sensor['client_id'],
    sensor['client_secret'],
    sensor['customer_id'],
    log_level
  )
  aruba_central_sensors.push(aruba_central)
end

producer = Kafka::Producer.new(
  config['kafka']['broker'],
  config['kafka']['producer_name'],
  log_level
)

generator = Kafka::EventGenerator.new(
  log_level
)

log_controller = ArubaLogger::LogController.new(
  'Main',
  log_level
)

loop do
  aruba_central_sensors.each do |aruba_central_sensor|
    begin
      log_controller.info("Processing sensor #{aruba_central_sensor}")
      location_data = generator.location_from_multiple_messages(aruba_central_sensor.fetch_location_production_data)
      status_data = generator.status_from_multiple_messages(aruba_central_sensor.fetch_ap_status_production_data)
      producer.send_kafka_multiple_msgs(location_data, config['kafka']['location_topic'])
      producer.send_kafka_multiple_msgs(status_data, config['kafka']['status_topic'])
    rescue StandardError => e
      log_controller.error("There was an error while proccesing sensor #{aruba_central_sensor} : #{e.message}")
      log_controller.error("Trace: #{e.backtrace.join("\n")}")
    end
  end
  sleep(config['service']['sleep_time'])
end
