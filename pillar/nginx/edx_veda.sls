{% set app_name = 'xpro-video-qa' %}
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set server_domain_names = env_data.purposes[app_name].domains %}

nginx:
  ng:
    install_from_source: True
    source_version: 1.15.1
    source_hash: c7206858d7f832b8ef73a45c9b8f8e436bcb1ee88db2bc85b8e438ecec9d5460
    certificates:
      mitx_wildcard:
        public_cert: __vault__::secret-operations/global/mitx_wildcard_cert>data>value
        private_key: __vault__::secret-operations/global/mitx_wildcard_cert>data>key
    servers:
      managed:
        {{ app_name }}:
          enabled: True
          config:
            - server:
                - server_name: {{ server_domain_names|tojson }}
                - listen:
                    - 80
                - listen:
                    - '[::]:80'
                - location /:
                    - return: 301 https://$host$request_uri
            - map $http_origin $cors_origin:
                - default: "null"
            - upstream veda_app_server:
                - server: 127.0.0.1:8555 fail_timeout=0
            - server:
                - server_name: {{ server_domain_names }}
                - listen:
                    - 443
                    - ssl
                    - default
                - listen:
                    - '[::]:443'
                    - ssl
                - root: # TODO
                - ssl_certificate: /etc/nginx/ssl/mitx_wildcard.crt
                - ssl_certificate_key: /etc/nginx/ssl/mitx_wildcard.key
                - ssl_stapling: 'on'
                - ssl_stapling_verify: 'on'
                - ssl_session_timeout: 1d
                - ssl_session_tickets: 'off'
                - ssl_protocols:
                    - TLSv1.1
                    - TLSv1.2
                    - TLSv1.3
                - ssl_ciphers: "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256\
                     :ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384\
                     :DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256\
                     :ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384\
                     :ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256\
                     :DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256\
                     :AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS"
                - ssl_prefer_server_ciphers: 'on'
                - resolver: 1.1.1.1
                - location ~ ^/static/(?P<file>.*):
                    - root: /edx/var/veda
                    - if ($request_method = 'OPTIONS'):
                        - add_header: 'Access-Control-Allow-Origin $cors_origin'
                        - add_header: 'Access-Control-Allow-Methods GET, POST, OPTIONS'
                        - add_header: 'Access-Control-Allow-Headers Authorization, USE-JWT-COOKIE'
                        - add_header: 'Access-Control-Max-Age 86400'
                        - add_header: 'Content-Type text/plain; charset=utf-8'
                        - add_header: 'Content-Length 0'
                        - return: 204
                    - add_header: "'Access-Control-Allow-Origin' $cors_origin always"
                    - add_header: "'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always"
                    - add_header: "'Access-Control-Allow-Credentials' true always"
                    - add_header: "'Vary' 'Accept-Encoding,Origin'"
                    - try_files:
                        - /staticfiles/$file
                        - '=404'
                - location ~ ^/media/(?P<file>.*):
                  - root: /edx/var/veda
                  - try_files:
                      - /media/$file
                      - =404
                - location /:
                    - try_files:
                        - $uri
                        - @proxy_to_app
                - location @proxy_to_app:
                    - proxy_set_header:
                        - X-Forwarded-Proto
                        - $http_x_forwarded_proto
                    - proxy_set_header:
                        - X-Forwarded-Port
                        - $http_x_forwarded_port
                    - proxy_set_header:
                        - X-Forwarded-For
                        - $http_x_forwarded_for
                    - proxy_set_header:
                        - X-Queue-Start
                        - "t=${msec}"
                    - proxy_set_header:
                        - Host
                        - $http_host
                    - proxy_redirect: off
                    - proxy_pass: http://veda_app_server
