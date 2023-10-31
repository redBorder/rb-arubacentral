require_relative './helpers/codecov_helper.rb'
require_relative '../src/kafka/producer.rb'
require 'test/unit'

# Test Kafka Producer
class ProducerTest < Test::Unit::TestCase
  def setup
    @producer = Kafka::Producer.new('localhost:9092', 'test-producer')
  end

  def test_send_to_kafka
    msg = { 'message' => 'hello world' }
    topic = 'test-topic'

    assert_nothing_raised do
      @producer.send_to_kafka(msg, topic)
    end
  end

  def test_send_kafka_multiple_msgs
    msgs = [
      { 'message' => 'hello world 1' },
      { 'message' => 'hello world 2' }
    ]
    topic = 'test-topic'

    assert_nothing_raised do
      @producer.send_kafka_multiple_msgs(msgs, topic)
    end
  end
end
