import requests, time

company_api_id = 'example_id'
company_api_secret = 'example_secret'
base_url = 'https://example.com/'

STATS_PER_PAGE = 100
STATS_URLS = ['/requests', '/requests/blocked', '/requests/cached']

# URL to authenticate
url = base_url + 'api/oauth/token'

# company API credentials
params = {
  'client_secret': company_api_secret,
  'client_id': company_api_id
}
# get access token
response = requests.post(url, params=params)
access_token = 'Bearer ' + response.json()['access_token']
print("access_token:%(access_token)s" % {'access_token': access_token } )

# list to store all company webapp IDs
webapps_ids = []

# URL to access company webapps_list
url = base_url + 'api/v3/company/webapps'

# add access token in a header
auth_header = { 'Authorization': access_token }
per_page = 100     # amount of company webapps load per page
current_page = 1   # start from page
load_data = True   # variable to stop while loop when all webapps checked

# while loop to paginate through all company webapps
while load_data:
  # load webapps
  response = requests.get(
      url,
      headers=auth_header,
      params={ 'per_page': per_page, 'page': current_page }
    ).json()

  # add webapps id to webapps_ids list
  for webapp in response:
    webapps_ids.append(webapp['id'])

  print("webapps-count:%(response)s" % {'response': len(response) } )

  # Check if last company webapps page reached
  load_data = per_page == len(response)
  current_page += 1

print("webapps-ids:%(ids)s" % {'ids': webapps_ids } )

# current time
time_to = int(time.time())
# current time - 24 hours
time_from = time_to - 24 * 60 * 60

print("timerange:%(from)i-%(to)i" % {'from': time_from, 'to': time_to } )

def load_stats(webapp_id, route):
  url = "%(base_url)s/api/v3/webapps/%(webapp_id)s/stats%(route)s" % {'base_url': base_url, 'webapp_id': webapp_id, 'route': route }
  results_offset = 0 # offset for data results to paginate over all stats
  load_data = True   # variable to stop while loop when all webapps stats checked

  webapps_stats = [] # list to store webapp stats data

  while load_data:
    params = { 'limit': STATS_PER_PAGE, 'from': time_from, 'to': time_to }

    # 0 offset is not suported by api
    if results_offset > 0:
      params.update({'offset': (results_offset * STATS_PER_PAGE) })

    # load stats data
    response = requests.get(
        url,
        headers=auth_header,
        params=params
      ).json()

    # print("response:%(response)s" % {'response': response } )
    print("webapp:%(webapp_id)s==%(iteration)i" % {'webapp_id': webapp_id , 'iteration': results_offset} )

    webapps_stats += response['data']

    # check if all stats loaded
    load_data = STATS_PER_PAGE == len(response['data'])
    results_offset += 1

  return webapps_stats

webapps_stats = {} # dictionary to store all webapp stats data

# iterate through all company webapps
for id in webapps_ids:
  # iterate through required stats
  for route in STATS_URLS:
    # add webapp id to dictionary if it not exists
    if id not in webapps_stats:
      webapps_stats[id] = {}

    webapps_stats[id][route] = load_stats(id, route)


print("stats:%(ids)s" % {'ids': webapps_stats } )

