#!/usr/bin/env ruby
require 'time'
require 'faraday'
require 'json'
require 'yaml'

class WebappSettings
  def initialize
    @arguments = serialize_arguments
    info unless ARGV.count.even? && (@arguments.key?(:waf) || @arguments.key?(:caching))

    @config  = YAML.load_file('config.yml')
    @webapps = read_webapps_from_file
    @connection = Faraday.new(url: @config['dojo_url'])
    @app_list = request('get', 'api/v2/webapps').fetch(:body)

    @arguments.key?(:waf) ? waf_rules : caching_rules
  end

  private

  def caching_rules
    read_caching_rules
    @webapps.each do |webapp|
      webapp_id = find_id(webapp)
      request('post', "/api/v2/webapps/#{webapp_id}/caching_rules", hash: @caching_rules)
      if @response[:status].to_s == '202'
        puts "Created caching rules for webapp '#{webapp}'"
      else
        puts "Error creating caching rule for '#{webapp}'"
        error_messages
        abort
      end
    end
    puts 'Done creating caching rules'
  end

  def read_caching_rules
    abort 'caching_rules.json cannot be found' unless File.file?('caching_rules.json')
    @caching_rules = JSON.parse(File.read('caching_rules.json'))
  end

  def waf_rules
    webapp_count = 1
    @webapps.each do |webapp|
      webapp_id = find_id(webapp)
      waf_rule_list = request('get', "api/v2/webapps/#{webapp_id}/waf_rules").fetch(:body)
      waf_rule_count = 1
      waf_rule_list.each do |rule|
        request('put', "api/v2/webapps/#{webapp_id}/waf_rules/#{rule['id']}", hash: { value: @arguments[:waf] })
        if @response[:status].to_s == '202'
          puts "#{webapp_count}.#{waf_rule_count} Created #{@arguments[:waf]} WAF rule '#{rule['title']}' for webapp '#{webapp}'"
        else
          puts "Error creating WAF rule '#{rule['title']}' for '#{webapp}'"
          error_messages
          abort
        end
        waf_rule_count += 1
        break if waf_rule_count == 3
      end
      webapp_count += 1
    end
    puts 'Done creating WAF rules'
    caching_rules if @arguments.key?(:caching) && @arguments[:caching] == 'true'
  end

  def error_messages
    puts "Response status: #{@response[:status]}, response body: #{@response[:body]}"
    puts 'Exiting.'
  end

  def find_id(domain)
    selected_app = @app_list.select { |app| app['domain'].include?(domain) }
    selected_app_id = selected_app.any? ? selected_app[0]['id'] : nil

    selected_app_id
  end

  def info
    puts 'Arguments:'
    puts '  To add waf rules:'
    puts '    --waf [alert, block, off]'
    puts '    Option chosen applies all WAF rules'
    puts '  To add caching rules:'
    puts '    --caching true'
    puts '    Applies caching rules specified in caching_rules.json'
    abort
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

  def serialize_arguments
    arguments = {}

    run = 0
    (ARGV.count / 2).times do |i|
      key = ARGV[i + run].dup
      value = ARGV[i + 1 + run].dup
      abort "argument #{key} is invalid" unless key.match(/--/) && key.gsub!('--', '')
      arguments[key.to_sym] = value
      run += 1
    end

    arguments
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

WebappSettings.new
