require 'poseidon'

module Kafka
    class Producer
        attr_accessor :producer, :host, :producer_name, :topic

        def initialize(host, producer_name, topic)
            @host = host
            @producer_name = producer_name
            @topic = topic
            @producer = Poseidon::Producer.new([@host], @producer_name)

        end

        def send_to_kafka(msg)
            begin
                messages = []
                messages << Poseidon::MessageToSend.new(@topic, msg.to_json)
                @producer.send_messages(messages)
            rescue
                p "Error producing messages to kafka #{@topic}..."
            end
        end

        def send_kafka_multiple_msgs(msgs)
            msgs.each do | msg |
                send_to_kafka(msg)
            end
        end
    end

    class EventGenerator
        def from_multiple_messages(data)
            result = []

            data.each do |item|
                json_message = {
                "StreamingNotification" => {
                    "subscriptionName" => "WLC",
                    "location" => {
                    "macAddress" => item[:client_mac_address],
                    "mapInfo" => {
                        "mapHierarchyString" => item[:topology]
                    },
                    "geoCoordinate" => {
                        "lattitude" => item[:lat],
                        "longitude" => item[:long]
                    },
                    "apMacAddress" => item[:ap_mac_address],
                    "dot11Status" => item[:associated] ? "associated" : "not associated"
                    },
                    "timestamp" => item[:time]
                }
                }

                result << json_message
            end

            result
        end
    end
end