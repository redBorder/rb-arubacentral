require_relative './api/aruba_client'
require_relative './helpers/aruba_config'
require_relative './kafka/producer.rb'

config = ConfigManager.load_config

aruba = ArubaREST::Client.new(
    config["aruba"]["gateway"],
    config["aruba"]["email"],
    config["aruba"]["password"],
    config["aruba"]["client_id"],
    config["aruba"]["client_secret"],
    config["aruba"]["customer_id"],
    config["aruba"]["base_url"]
)

producer = Kafka::Producer.new(
    config["kafka"]["broker"],
    config["kafka"]["producer_name"],
    config["kafka"]["topic"]
)

generator = Kafka::EventGenerator.new()

while true do
    data = generator.from_multiple_messages(aruba.fetch_production_data())
    producer.send_kafka_multiple_msgs(data)
    sleep(config["service"]["sleep_time"])
end