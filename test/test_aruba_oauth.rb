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
require_relative '../bin/helpers/aruba_oauth'
require 'test/unit'

# Test Oauth Service
class OAuthHelperTest < Test::Unit::TestCase
  FakeResponse = Struct.new(:headers, :body) do
    def [](key)
      headers[key]
    end
  end

  def setup
    @oauth_helper = OAuthHelper

    # Avoid hitting the real Aruba Central API from the tests
    OAuthHelper.singleton_class.send(:alias_method, :original_post_request, :post_request)
    OAuthHelper.define_singleton_method(:post_request) do |url, _body, _fields|
      if url.include?('/oauth2/token')
        FakeResponse.new({}, '{"error":"invalid_client"}')
      elsif url.include?('/api/login')
        FakeResponse.new({ 'Set-Cookie' => 'session=test_session; csrftoken=test_csrf; Path=/' }, '{}')
      else
        FakeResponse.new({}, '{"auth_code":"test_code"}')
      end
    end
  end

  def teardown
    OAuthHelper.singleton_class.send(:remove_method, :post_request)
    OAuthHelper.singleton_class.send(:alias_method, :post_request, :original_post_request)
    OAuthHelper.singleton_class.send(:remove_method, :original_post_request)
  end

  def test_oauth_fails
    client_id = '1234567890'
    client_secret = 'secret'
    customer_id = 'my_customer_id'

    response = @oauth_helper.oauth('https://apigw-eucentral3.central.arubanetworks.com', 'root', 'root', client_id, client_secret, customer_id)
    puts response['error']
    assert_equal('invalid_client', response['error'])
  end
end
