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
require_relative '../bin/kafka/producer'
require 'test/unit'

# Test Kafka Producer
class ProducerTest < Test::Unit::TestCase
  def setup
    @producer = Kafka::Producer.new('localhost:9092', 'test-producer', 0)
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
