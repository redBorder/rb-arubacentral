# frozen_string_literal: true

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

require 'easycache'
require 'net/http'
require 'uri'
require 'json'

#
# Simple HTTP Client for making/handling http requests/responses
#
class ArubaHTTP
  def make_api_request(api_endpoint)
    log_debug("Requesting data from #{api_endpoint}")
    uri = build_uri(api_endpoint)
    http = build_http(uri)
    request = build_request(uri)
    send_request(http, request)
  rescue StandardError => e
    handle_error(e, api_endpoint)
    nil
  end

  def fetch_data(api_endpoint, cache_name)
    cache_key = "api_response:#{api_endpoint}"
    cache = @cache_keys.include?(cache_name)
    cache_refresh = @cache_ttl.fetch(cache_name.to_sym, 0).to_i
    log_debug("fetch data from #{cache_key}, cached[#{cache}], cache_refresh_ttl[#{cache_refresh}]")
    @cache.fetch(cache_key, cache_refresh, cache) do
      response = make_api_request(api_endpoint)
      parse_response(response)
    end
  end

  private

  def log_debug(message)
    @log_controller.debug(message)
  end

  def build_uri(api_endpoint)
    URI.join(@gateway, api_endpoint)
  end

  def build_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.read_timeout = 30
    http.open_timeout = 10
    http
  end

  def build_request(uri)
    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = "Bearer #{@self_token}"
    request['Content-Type'] = 'application/json'
    log_debug("Making request to..#{uri.request_uri}")
    request
  end

  def send_request(http, request)
    response = http.request(request)
    log_debug('Request finished')
    response
  end

  def handle_error(error, api_endpoint)
    case error
    when Net::ReadTimeout
      log_error("Timeout while waiting for a response from #{api_endpoint}")
    when Net::OpenTimeout
      log_error("Timeout while waiting for opening request #{api_endpoint}")
    else
      log_error("An unexpected error occurred: #{error.message}")
    end
  end

  def parse_response(response)
    return {} unless response

    log_debug("Response status code is #{response.code}")

    case response.code
    when '200'
      parse_successful_response(response)
    when '401'
      handle_401_response(response)
    else
      {}
    end
  end

  def parse_successful_response(response)
    JSON.parse(response.body)
  end

  def handle_401_response(_response)
    log_debug('401, refreshing token')
    refresh_oauth_token
    re_request_data(api_endpoint)
  end

  def re_request_data(api_endpoint)
    response = make_api_request(api_endpoint)
    log_debug('Re-requesting data...')
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      {}
    end
  end

  def log_error(message)
    @log_controller.error(message)
  end
end
