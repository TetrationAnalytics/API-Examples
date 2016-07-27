## Ruby

### Usage

##### Getting API access token

```
ruby purge.rb get_token CLIENT_ID CLIENT_SECRET
```

##### Getting list of webapps with their ids

```
ruby purge.rb webapps ACCESS_TOKEN ENVIRONMENT
```

- environment can be either *production* or *staging*

##### Purging cache

```
ruby purge.rb purge_cache ACCESS_TOKEN WEBAPP_ID RESOURCES
```

- Can be multiple resources. Must be separated by space.

##### Getting task status

```
ruby purge.rb task_status ACCESS_TOKEN TASK_ID
```

- Will check every 5 seconds until its finished, reporting current status back.


### Setup


```
$ gem install faraday
```

To run the script follow these steps:

- to purge entire cache, type .\FinalScriptv1.3.ps1 <client_id> <client_secret> <domain name>
For example: .\Finalscriptv1.3.ps1 36c690d0353d7 f6143341868fa515 mydomain.com

- to purge particular resource, type .\FinalScriptv1.3.ps1 <client_id> <client_secret> <domain name> <web resource>
For example: .\Finalscriptv1.3.ps1 36c690d0353d7 f6143341868fa515 mydomain.com mydomain.com/images

The output will contain the status after the request is completed and the response has been received, along with the task ID:
{"status":"ok","task_id":"677d77b0abd301323762000c29359632"}
