require_relative '../src/helpers/aruba_oauth.rb'
require 'test/unit'

# Test Oauth Service
class OAuthHelperTest < Test::Unit::TestCase
  def setup
    @oauth_helper = OAuthHelper
  end

  def test_oauth_fails
    client_id = '1234567890'
    client_secret = 'secret'
    customer_id = 'my_customer_id'

    response = @oauth_helper.oauth('https://apigw-eucentral3.central.arubanetworks.com', 'root', 'root', client_id, client_secret, customer_id)
    assert_equal('invalid_client', response['error'])
  end
end
