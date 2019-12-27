{% set app_name = 'mitx-cas' %}
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set server_domain_names = env_data.purposes['mitx-cas'].domains %}
{% set server_domains = {
'mitx-qa': server_domain_names[0],
'mitx-production': server_domain_names[1]
%}

nginx:
  install_from_source: True
  source_version: 1.15.1
  source_hash: c7206858d7f832b8ef73a45c9b8f8e436bcb1ee88db2bc85b8e438ecec9d5460
  certificates:
    mitx_wildcard:
      public_cert: __vault__::secret-operations/global/mitx_wildcard_cert>data>value
      private_key: __vault__::secret-operations/global/mitx_wildcard_cert>data>key
  server:
    extra_config:
      shib_params:
        source_path: salt://nginx/ng/files/nginx.conf
        shib_request_set:
          - $shib_uid $upstream_http_variable_uid
          - $shib_eppn $upstream_http_variable_eppn
          - $shib_given_name $upstream_http_variable_givenName
          - $shib_mail $upstream_http_variable_mail
          - $shib_surname $upstream_http_variable_sn
        uwsgi_param:
          - REMOTE_USER $shib_eppn
          - REMOTE_USER $shib_uid if_not_empty
          - mail $shib_mail
          - givenName $shib_given_name
          - sn $shib_surname
  servers:
    managed:
      {{ app_name }}:
        enabled: True
        config:
          - server:
              - server_name: {{ server_domains[ENVIRONMENT] }} {# This is a hack to work around the way that shibboleth/init.sls is set up for entityID  (TMM 2018-07-24) #}
              - listen:
                  - 80
              - listen:
                  - '[::]:80'
              - location /:
                  - return: 301 https://$host$request_uri
          - server:
              - server_name: {{ server_domains[ENVIRONMENT] }}{# This is a hack to work around the way that shibboleth/init.sls is set up for entityID  (TMM 2018-07-24) #}
              - listen:
                  - 443
                  - ssl
                  - default
              - listen:
                  - '[::]:443'
                  - ssl
              - root: /opt/mitx-cas/
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
              - ssl_ciphers: "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256\
                  :DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384\
                  :ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256\
                  :ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256"
              - ssl_prefer_server_ciphers: 'on'
              - resolver: 1.1.1.1
              - location /shibauthorizer:
                  - internal: ''
                  - include: fastcgi_params
                  - include: includes/shib_fastcgi_params
                  - fastcgi_pass: 'unix:/run/shibauthorizer.sock'
              - location /Shibboleth.sso:
                  - include: fastcgi_params
                  - include: includes/shib_fastcgi_params
                  - fastcgi_pass: 'unix:/run/shibresponder.sock'
              - location /shib:
                  - include: includes/shib_clear_headers
                  - shib_request: /shibauthorizer
                  - shib_request_use_headers: 'on'
                  - include: conf.d/shib_params.conf
                  - include: uwsgi_params
                  - uwsgi_ignore_client_abort: 'on'
                  - uwsgi_pass: unix:/var/run/uwsgi/mitx-cas.sock
              - location /:
                  - include: uwsgi_params
                  - uwsgi_ignore_client_abort: 'on'
                  - uwsgi_pass: unix:/var/run/uwsgi/mitx-cas.sock
              - location ~* /static/(.*$):
                  - expires: max
                  - add_header: 'Access-Control-Allow-Origin *'
                  - try_files:
                      - $uri
                      - $uri/
                      - /staticfiles/$1
                      - /staticfiles/$1/
                      - =404
