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

require_relative './helpers/codecov_helper.rb'
require_relative '../lib/api/aruba_client.rb'
require 'test/unit'

# Test Aruba REST
class ArubaRESTClientTest < Test::Unit::TestCase
  def setup
    @client = ArubaREST::Client.new('https://apigw-eucentral3.central.arubanetworks.com', 'username', 'password', 'client_id', 'client_secret', 'client_customer_id')
  end

  def test_initialize
    assert_equal('https://apigw-eucentral3.central.arubanetworks.com', @client.gateway)
    assert_equal('username', @client.username)
    assert_equal('password', @client.password)
    assert_equal('client_id', @client.client_id)
    assert_equal('client_secret', @client.client_secret)
    assert_equal('client_customer_id', @client.client_customer_id)
  end

  def test_refresh_oauth_token
    lambda { |_gateway, _username, _password, _client_id, _client_secret, _client_customer_id|
      { 'access_token' => 'expired_token' }
    }

    @client.make_api_request('/visualrf_api/v1/campus')

    assert_not_equal('expired_token', @client.self_token)
  end

  def test_fetch_data
    data = @client.fetch_data('/visualrf_api/v1/campus')

    assert_equal({}, data)
  end
end
