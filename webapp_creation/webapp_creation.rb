#!/usr/bin/env ruby
require 'time'
require 'faraday'
require 'json'
require 'yaml'

class CreateWebapps
  def initialize
    @config = YAML.load_file('config.yml')
    read_template
    read_webapps if @app_template['domain'] == 'file'

    @connection = Faraday.new(url: @config['dojo_url'])

    create_webapps
  end

  private

  def create_webapps
    @webapps.each do |webapp|
      request('post', 'api/v2/webapps', hash: hash(webapp))
      if @response[:status].to_s == '202'
        puts "Created webapp: #{webapp}"
      else
        puts "Error creating webapp: #{webapp}, response status: #{@response[:status]}, response body: #{@response[:body]}"
        abort 'Exiting.'
      end
    end
    puts 'Done creating webapps.'
  end

  def hash(domain)
    hash = @app_template.dup
    hash['domain'] = domain
    if @app_template['base_domain_redirect_from'] == 'www'
      hash['base_domain_redirect_from'] = domain.gsub(%r{^(https?:\/\/)?(www\.)?}, '')
    end

    hash
  end

  def read_template
    abort 'webapp_template.json cannot be found' unless File.file?('webapp_template.json')
    @app_template = JSON.parse(File.read('webapp_template.json'))
    @webapps = [@app_template['domain']]
  end

  def read_webapps
    abort 'webapps.txt cannot be found' unless File.file?('webapps.txt')
    @webapps = []
    text = File.open('webapps.txt').read
    text.gsub!(/\r\n?/, "\n")
    text.each_line do |line|
      @webapps << line.chomp
    end

    @webapps
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

CreateWebapps.new
