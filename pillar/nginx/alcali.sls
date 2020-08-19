{% set app_name = 'alcali' %}
{% set env_settings = salt.file.read(salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml"))|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'operations') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set server_domain_names = env_data.purposes[app_name].domains %}

nginx:
  install_from_ppa: True
  certificates:
    odl.mit.edu:
      public_cert: __vault__::secret-operations/global/odl_wildcard_cert>data>value
      private_key: __vault__::secret-operations/global/odl_wildcard_cert>data>key
  servers:
    managed:
      {{ app_name }}:
        enabled: True
        config:
          - upstream app_server:
              - server: '0.0.0.0:8000 fail_timeout=0'
          - server:
              - server_name: {{ server_domain_names|tojson }}
              - listen: 80
              - listen: '[::]:80'
              - location /:
                  - return: 301 https://$host$request_uri
          - server:
              - server_name: {{ server_domain_names|tojson }}
              - listen: '443 ssl default_server'
              - listen: '[::]:443 ssl'
              - ssl_certificate: /etc/nginx/ssl/odl_wildcard.crt
              - ssl_certificate_key: /etc/nginx/ssl/odl_wildcard.key
              - ssl_stapling: 'on'
              - ssl_stapling_verify: 'on'
              - ssl_session_timeout: 1d
              - ssl_session_tickets: 'off'
              - ssl_protocols: 'TLSv1.2 TLSv1.3'
              - ssl_ciphers: "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256\
                  :DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384\
                  :ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256\
                  :ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256"
              - ssl_prefer_server_ciphers: 'on'
              - resolver: 1.1.1.1
              - location /:
                  - try_files: $uri @proxy_to_app
              - location @proxy_to_app:
                  - proxy_set_header: 'X-Forwarded-For $proxy_add_x_forwarded_for'
                  - proxy_set_header: 'X-Forwarded-Proto $scheme'
                  - proxy_set_header: 'Host $http_host'
                  - proxy_redirect: off
                  - proxy_pass: 'http://app_server'
