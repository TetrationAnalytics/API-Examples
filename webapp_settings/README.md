# Creates Webapps from a file

  - Requires /config.yml setup by the example.
  - If caching rules needs to be added, requires /caching-rules.json setup by the example.
  - Requires /config.yml setup by the example.
  - Requires webapps domains written one per line in /webapps.txt.
  - Run: `./webapp_creation.rb --waf [alert_only, block, off]` to add waf rules for webapps from the webapps.txt file
      - or run `./webapp_creation.rb --caching true` to add caching rules for webapps from the webapps.txt file
      - or run both `./webapp_creation.rb --waf block --caching true`

# Caching Rules Template

  - name:                           required, string.
  - setting_type:                   required, must be one of: file_cache_rule, url_cache_rule,
                                    never_file_cache_rule, never_url_cache_rule.
  - expire_after:                   optional, integer.
  - expire_time_unit:               optional, must be one of: s (second), m (minute),
                                    h (hour), d (day), w (week), M (mounth).
  - client_expire_after:            optional, integer.
  - client_expire_time_unit:        optional, must be one of: s (second), m (minute),
                                    h (hour), d (day), w (week), M (mounth).
  - client_expire_after_enabled:    optional, true or false.
  - cache_set:                      optional, string.
  - cache_set_urls:                 optional, array of objects.
    - cache_set_urls[match_type]:   required if cache_set_urls is used, string.
    - cache_set_urls[url]:          required if cache_set_urls is used, string.
