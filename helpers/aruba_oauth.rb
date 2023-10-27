require 'net/http'
require 'uri'
require 'json'

module OAuthHelper
  def self.post_request(url, body, fields)
    uri = URI.parse(url)
    puts url
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    fields.each { |key, value| request[key] = value }
    request.body = body.to_json
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    response = http.request(request)
    response
  end

  def self.get_cookie(cookies, key)
    value = ""
    cookie = cookies.match(/#{key}=([^;]+)/)
    if cookie
      value = cookie[1]
    else
      puts "#{key} cookie not found in the string."
    end
    value
  end

  def self.oauth(endpoint, username, password, client_id, client_secret, customer_id)
    puts endpoint
    csrf_token = ""
    session = ""

    session_url = "#{endpoint}/oauth2/authorize/central/api/login?client_id=#{client_id}"
    credentials = {
      "username" => username,
      "password" => password
    }
    response = post_request(session_url, credentials, {})
    
    if response.is_a?(Net::HTTPSuccess)
      cookies = response['Set-Cookie']
      session = get_cookie(cookies, "session")
      csrf_token = get_cookie(cookies, "csrftoken")
    else
      puts "Could not create session. Response code: #{response.code}, Response: #{response.body}"
      exit 1
    end

    auth_code_url = "#{endpoint}/oauth2/authorize/central/api/?client_id=#{client_id}&response_type=code&scope=read"
    customer_id_params = {
      "customer_id" => customer_id
    }
    response = post_request(auth_code_url, customer_id_params, {'X-CSRF-Token' => csrf_token, 'Cookie' => "session=#{session}" })

    if response.is_a?(Net::HTTPSuccess)
      response_data = JSON.parse(response.body)
      auth_code = response_data['auth_code']
    else
      puts "Could not get auth_code. Response code: #{response.code}, Response: #{response.body}"
      exit 1
    end

    token_url = "#{endpoint}/oauth2/token"
    token_body = {
      "client_id" => client_id,
      "client_secret" => client_secret,
      "grant_type" => "authorization_code",
      "code" => auth_code
    }
    response = post_request(token_url, token_body, {})

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      puts "Request was not successful"
      exit 1
    end
  end
end