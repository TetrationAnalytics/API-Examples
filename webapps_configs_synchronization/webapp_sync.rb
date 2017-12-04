# frozen_string_literal: true
require 'faraday'
require 'json'

BASE_WEBAPP = 'my-base-webapp.com'.freeze
COMPANIES_CREDENTIALS =
  [
    {
      client_id: 'client_id_1',
      client_secret: 'client_secret_1'
    },
    {
      client_id: 'client_id_1',
      client_secret: 'client_secret_1'
    }
  ].freeze

PORTAL_DOMAIN = 'https://my-portal.com'.freeze
TEMPLATE_NAME = 'my-template-name'.freeze
RESULTS_PER_PAGE = 100

api_connection = Faraday.new(url: PORTAL_DOMAIN) do |faraday|
  faraday.request  :url_encoded            # form-encode POST params
  # faraday.response :logger               # log requests to STDOUT
  faraday.adapter  Faraday.default_adapter # make requests with Net::HTTP
  faraday.headers['Content-Type'] = 'application/json'
end

# variable used to store base webapp template and share between companies
template_config = nil

def set_authorization_header(connection, credentials)
  data = connection.post do |req|
    req.url '/api/oauth/token'
    req.body = credentials.to_json
  end

  # stop script unless authentication was successfull, response code 200
  exit unless data.status == 200

  # parse response and take access token from it
  # set Authorization header for further requests
  response = JSON.parse(data.body)
  connection.headers['Authorization'] = "Bearer #{response['access_token']}"
end

def select_webapps(connection, page)
  # API request to get company webapps
  data = connection.get do |req|
    req.url '/api/v3/company/webapps'
    req.body =
      {
        per_page: RESULTS_PER_PAGE,
        page: page
      }.to_json
  end

  webapps = JSON.parse(data.body)
end

def find_template_id(connection)
  templates_count = 0      # templates found amount per page
  filtered_templates = []  # templates with TEMPLATE_NAME name
  page = 1

  begin
    # API call to get templates
    data = connection.get do |req|
    req.url '/api/v3/company/templates'
      req.body =
        {
          per_page: RESULTS_PER_PAGE,
          page: page
        }.to_json
    end

    templates = JSON.parse(data.body)

    # select templates with TEMPLATE_NAME from returned results
    templates.each do |template|
      if template['name'] == TEMPLATE_NAME
        filtered_templates << template
      end
    end

    templates_count = templates.size
    page += 1
  end while templates_count > 0

  if filtered_templates.size > 1   # stop script if duplicated names are detected
    puts 'template name duplicates detected'
    exit
  end

  # take template id
  template_id = filtered_templates&.first&.fetch('id', nil)

  return template_id
end

def delete_template(connection, template_id)
  # delete template API request
  data =
    connection.delete do |req|
      req.url "/api/v3/company/templates/#{template_id}"
    end

  if (data.status == 204)
    puts 'Old template was deleted'
  else
    puts 'Old template deletion failed'
    exit
  end
end

def create_tempate(connection, webapp_id)
  # create template API request
  data =
    connection.post do |req|
      req.url '/api/v3/company/templates'
      req.body =
        {
          name: TEMPLATE_NAME,
          description: 'template generated throught API',
          webapp_id: webapp_id
        }.to_json
    end

  if (data.status == 200)
    puts 'New template created'
  else
    puts 'Failed to create new template'
    exit
  end
end

def apply_template(connection, webapp_id, template_id)
  # apply template to webapp API request
  data =
    connection.post do |req|
      req.url "/api/v3/company/templates/#{template_id}"
      req.body = { webapp_id: webapp_id }.to_json
    end

  if [204, 202].include? data.status
    puts "Template (#{template_id}) applied for webapp (#{webapp_id})"
  else
    puts "Failed apply template (#{template_id}) for webapp (#{webapp_id})"
    exit
  end
end

def publish_changes(connection, webapp_id)
  # publish webapp pendding changes
  data =
    connection.post do |req|
      req.url "/api/v3/webapps/#{webapp_id}/changes/pending"
    end

  if data.status == 202
    puts "Webapp (#{webapp_id}) changes published"
  else
    puts "Webapp (#{webapp_id}) changes not found"
  end
end

def update_template_config(connection, template_id, config)
  # API call to update template configuration
  data =
    connection.put do |req|
      req.url "/api/v3/company/templates/#{template_id}"
      req.body = { template_json: config.to_json }.to_json
    end

  if (data.status == 200)
    puts 'Template updated'
  else
    puts 'template update failed'
    exit
  end
end

def parse_tempate_json(connection, template_id)
  # API call to get template configuration
  data =
    connection.get do |req|
      req.url "/api/v3/company/templates/#{template_id}"
    end

  if (data.status == 200)
    puts 'Template found'
  else
    puts 'Failed to find template'
    exit
  end

  JSON.parse(data.body).fetch('template_json', nil)
end

COMPANIES_CREDENTIALS.each_with_index do |credentials, index|
  company_with_base_webapp = template_config.nil?
  set_authorization_header(api_connection, credentials)

  webapps_count = 0
  base_webapp_id = nil
  webapps_ids = []
  page = 1

  begin
    webapps = select_webapps(api_connection, page)

    webapps.each do |webapp|
      next unless webapp['environment'] == 'production' # skip staging webapps

      webapps_ids << webapp['id']
      # search for BASE_WEBAPP in first company of COMPANIES_CREDENTIALS list
      if(webapp['domain'] == BASE_WEBAPP && company_with_base_webapp)
        base_webapp_id = webapp['id']
      end
    end

    webapps_count = webapps.size
    page += 1
  end while webapps_count == RESULTS_PER_PAGE

  if company_with_base_webapp
    if base_webapp_id.nil?
      puts 'Base webapp not found'
      exit
    else
      puts "Base webapp found id: #{base_webapp_id}"
    end
  elsif webapps_ids.empty?
    puts "Comapny ##{index} has no webapps"
    next
  end

  # Search for template with TEMPLATE_NAME name
  template_id = find_template_id(api_connection)

  # Delete old template if exists
  if template_id
    puts "Old template found id: #{template_id}"
    delete_template(api_connection, template_id)
  else
    puts 'Old template was not found'
  end

  # Create new template by base or first in company webapp
  create_tempate(api_connection, base_webapp_id || webapps_ids.first)

  # create template API doesn't return tempate ID so we iterate trought all
  # templates and find it by name
  template_id = find_template_id(api_connection)

  if company_with_base_webapp
    # save base webapp config for other companies
    template_config = parse_tempate_json(api_connection, template_id)
  else
    # update config to match base_webapp configuration
    update_template_config(api_connection, template_id, template_config)
  end

  # apply and publish changes for all webapps in current company
  webapps_ids.each do |webapp_id|
    next if webapp_id == base_webapp_id # skip base webapp

    apply_template(api_connection, webapp_id, template_id)
    publish_changes(api_connection, webapp_id)
  end
end
