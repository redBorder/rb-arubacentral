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

require 'net/http'
require 'uri'
require 'json'

# Oauth module to login into aruba central
module OAuthHelper
  def self.oauth(endpoint, username, password, client_id, client_secret, customer_id)
    session_url = "#{endpoint}/oauth2/authorize/central/api/login?client_id=#{client_id}"
    credentials = { 'username' => username, 'password' => password }
    response = post_request(session_url, credentials, {})
    cookies = response['Set-Cookie']
    session = OAuthHelper.get_cookie(cookies, 'session')
    csrf_token = OAuthHelper.get_cookie(cookies, 'csrftoken')
    auth_code_url = "#{endpoint}/oauth2/authorize/central/api/?client_id=#{client_id}&response_type=code&scope=read"
    customer_id_params = { 'customer_id' => customer_id }
    response = post_request(auth_code_url, customer_id_params, 'X-CSRF-Token' => csrf_token, 'Cookie' => "session=#{session}")
    auth_code = JSON.parse(response.body)['auth_code']
    token_url = "#{endpoint}/oauth2/token"
    token_body = { 'client_id' => client_id, 'client_secret' => client_secret, 'grant_type' => 'authorization_code', 'code' => auth_code }
    response = post_request(token_url, token_body, {})
    JSON.parse(response.body)
  end

  private_class_method

  def self.post_request(url, body, fields)
    uri = URI.parse(url)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    fields.each { |key, value| request[key] = value }
    request.body = body.to_json
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.request(request)
  end

  private_class_method

  def self.get_cookie(cookies, key)
    value = ''
    cookie = cookies.match(/#{key}=([^;]+)/)
    if cookie
      value = cookie[1]
    else
      puts "#{key} cookie not found in the string."
    end
    value
  end
end
