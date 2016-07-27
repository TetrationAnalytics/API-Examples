#!/usr/bin/env ruby
require 'faraday'
require 'JSON'

class API
  API_URL = "https://dojo.zenedge.com"

  class << self
    def get_token(client_id, client_secret)
      resp = client.post do |req|
        req.url '/api/oauth/token'
        req.params['client_id'] = client_id
        req.params['client_secret'] = client_secret
      end
      JSON.parse(resp.body).fetch('access_token')
    end

    def purge_cache(authorization, webapp_id, resources)
      resp = client.post do |req|
        req.url "/api/v3/webapps/#{webapp_id}/purge_cache"
        req.headers['Authorization'] = "Bearer #{authorization}"
        req.params['purge_resources'] = [resources].flatten
      end

      if resp.status == 404
        raise 'Web application ID is incorrect'
      else
        JSON.parse(resp.body).fetch('task_id')
      end
    end

    def task_status(authorization, task_id)
      loop do
        resp = client.get do |req|
          req.url "/api/v3/webapps/tasks/#{task_id}"
          req.headers['Authorization'] = "Bearer #{authorization}"
        end
        status = JSON.parse(resp.body).fetch('status')
        puts "Current task status: #{status}"
        break if status == 'finished'
        sleep 5
      end
    end

    def webapps(authorization, environment)
      resp = client.get do |req|
        req.url "/api/v3/company/webapps"
        req.params['environment'] = environment
        req.headers['Authorization'] = "Bearer #{authorization}"
      end
      printf "%-20s %s\n", 'Name', 'ID'
      JSON.parse(resp.body).each do |webapp|
        printf "%-20s %s\n", webapp.fetch('name'), webapp.fetch('id')
      end
    end

    private

    def client
      Faraday.new(url: API_URL) do |faraday|
        faraday.request  :url_encoded
        faraday.adapter  Faraday.default_adapter
      end
    end
  end
end

case ARGV[0]
when 'get_token'
  puts API.get_token(ARGV[1], ARGV[2])
when 'purge_cache'
  puts API.purge_cache(ARGV[1], ARGV[2], ARGV[3..-1])
when 'task_status'
  API.task_status(ARGV[1], ARGV[2])
when 'webapps'
  API.webapps(ARGV[1], ARGV[2])
end
