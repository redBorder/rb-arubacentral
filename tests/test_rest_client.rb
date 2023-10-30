require 'test/unit'
require_relative '../src/api/aruba_client.rb'

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
