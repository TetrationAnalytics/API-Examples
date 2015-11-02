#!/usr/bin/env ruby
require 'time'
require 'faraday'
require 'json'
require 'yaml'

class DeleteWebapps
  def initialize
    @config  = YAML.load_file('config.yml')
    @webapps = read_webapps_from_file
    @connection = Faraday.new(url: @config['dojo_url'])
    @app_list = request('get', 'api/v2/webapps', {}).fetch(:body)

    delete_webapps
  end

  private

  def find_id(domain)
    webapp = @app_list.select { |app| app['domain'].include?(domain) }
    webapp_id = webapp.any? ? webapp[0]['id'] : nil

    webapp_id
  end

  def delete_webapps
    @webapps.each do |webapp|
      webapp_id = find_id(webapp)
      request('delete', "api/v2/webapps/#{webapp_id}", {})
      if @response[:status].to_s == '202'
        puts "Deleted webapp: #{webapp}"
      else
        puts "Error deleting webapp: #{webapp}, response status: #{@response[:status]}, response body: #{@response[:body]}"
        abort 'Exiting.'
      end
    end
    puts 'Done deleting webapps'
  end

  def read_webapps_from_file
    webapps = []
    text = File.open('webapps.txt').read
    text.gsub!(/\r\n?/, "\n")
    text.each_line do |line|
      webapps << line.chomp
    end

    webapps
  end

  def request(method, path, hash: {})
    method = method.downcase.to_sym

    fail format('Unknown request method type %s', method) unless [:get, :put, :post, :delete].include? method

    raw_response = @connection.send(method.to_sym) do |req|
      req.url path
      req.params['access_token'] = access_token
      req.headers['Content-Type'] = 'application/json'
      req.body = hash.to_json unless hash.empty?
    end

    response_body = {}
    response_body = JSON.parse(raw_response.body) if raw_response.body =~ /\{.*\}/

    @response = { headers: raw_response.headers, status: raw_response.status, body: response_body }
  end

  def access_token
    refresh_token if expired?
    @access_token
  end

  def refresh_token
    started_at = Time.now

    response = @connection.post '/api/oauth/token', {
      client_id: @config['client_id'],
      client_secret: @config['client_secret']
    }

    response = JSON.parse(response.body, symbolize_names: true)
    @access_token = response[:access_token]
    @expires_at = started_at + response[:expires_in]
  end

  def expired?
    return true unless @expires_at
    (@expires_at <=> Time.now) == -1
  end
end

DeleteWebapps.new
