To run the script follow these steps:

- to purge entire cache, type .\FinalScriptv1.3.ps1 <client_id> <client_secret> <domain name>
For example: .\Finalscriptv1.3.ps1 36c690d0353d7 f6143341868fa515 mydomain.com

- to purge particular resource, type .\FinalScriptv1.3.ps1 <client_id> <client_secret> <domain name> <web resource>
For example: .\Finalscriptv1.3.ps1 36c690d0353d7 f6143341868fa515 mydomain.com mydomain.com/images

The output will contain the status after the request is completed and the response has been received, along with the task ID:
{"status":"ok","task_id":"677d77b0abd301323762000c29359632"}
