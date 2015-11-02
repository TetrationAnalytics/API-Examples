# Creates listed webapps

  - Requires /config.yml setup by the example
  - Requires webapps domains written one per line in /webapps.txt
  - Requires webapp template filled in in /webapp_template.txt
  - Run: `./webapp_creation.rb` to delete webapps from the webapps.txt file

# Template

  - domain:                     required, string. If you want to create multiple webapps with different domains,
                                but same settings, use string "file". Otherwise, one webapp with specified domain
                                will be created.
  - additional_domains:         optional, array of objects.
    - name:                     required if additional_domains is used, string.
  - origin_servers:             required, array of objects.
    - ip:                       required, must be string
    - port:                     required, must be an integer.
    - weight:                   required, must be an integer.
  - backup_servers:             optional, array of objects.
    - ip:                       required if backup_servers is used, string
    - port:                     required if backup_servers is used, integer
  - base_domain_redirect_from:  optional, string. If you want to use same domain without 'www.', use string "www"
