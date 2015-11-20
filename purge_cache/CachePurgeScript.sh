#!/bin/bash
client_id=$1    #command line argument 1
client_secret=$2        #command line argument 2
client_credentials="client_credentials"
webapp_domain=$3        #command line argument 3
webapp_resources=$4

#Now we get the oauth token
response=$(curl -X POST -s https://dojo.zenedge.com/api/oauth/token \
        -d client_id=$client_id \
        -d client_secret=$client_secret \
        -d grant_type=$client_credentials)

#parse the response to extract the token
access_token=$(echo -e "$response" | \
                 grep -Po '"access_token" *: *.*?[^\\]",' | \
                 awk -F'"' '{ print $4 }')

#check if web resource is given in command line, if yes purge that resource
if [ -n "$webapp_resources" ]; then
        response1=$(curl -H "Authorization: Bearer $access_token" -X PUT -s https://dojo.zenedge.com/api/v1/cache/purge \
                -d webapp_domain=$webapp_domain \
                -d webapp_resources=$webapp_resources)
fi

#if web resource is not given, purge entire cache for that domain
if [ ! "$webapp_resources" ]; then
        response1=$(curl -H "Authorization: Bearer $access_token" -X PUT -s https://dojo.zenedge.com/api/v1/cache/purge_all \
                -d webapp_domain=$webapp_domain)
fi

echo $response1

