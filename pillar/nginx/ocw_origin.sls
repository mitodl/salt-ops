# Example Grains:
#   environment: ocw
#   roles: ocw-origin
#   ocw-environment: production
#   ocw-deployment: staging
#

{% set app_name = 'ocw-origin' %}
{% set env_settings = salt.file.read(salt.cp.cache_file("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml"))|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'ocw') %}
#
# FIXME: The ocw-environment and ocw-deployment grains are not created by Salt
# Cloud configuration. They have to be added after instances are created.
{% set OCW_ENVIRONMENT = salt.grains.get('ocw-environment') %}
{% set OCW_DEPLOYMENT = salt.grains.get('ocw-deployment') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set server_domain_names = env_data.purposes[app_name].domains[OCW_ENVIRONMENT][OCW_DEPLOYMENT] %}


nginx:
  install_from_repo: True
  certificates:
    odl_wildcard:
      public_cert: __vault__::secret-operations/global/odl_wildcard_cert>data>value
      private_key: __vault__::secret-operations/global/odl_wildcard_cert>data>key
  servers:
    managed:
      {{ app_name }}:
        enabled: True
        config:
          - server:
              - server_name: {{ server_domain_names|tojson }}
              - listen: 80
              - listen: '[::]:80'
              - location ~ /.well-known:
                  - allow: all
              - location /courses/edx_courses.json:
                  - root: /var/www/ocw
                  - allow: all
              - location /:
                  - return: 301 https://$host$request_uri
          - server:
              - server_name: {{ server_domain_names|tojson }}
              - listen: '443 ssl default_server'
              - listen: '[::]:443 ssl'
              - root: /var/www/ocw
              - ssl_certificate: /etc/nginx/ssl/odl_wildcard.crt
              - ssl_certificate_key: /etc/nginx/ssl/odl_wildcard.key
              - ssl_stapling: 'on'
              - ssl_stapling_verify: 'on'
              - ssl_session_timeout: 1d
              - ssl_session_tickets: 'off'
              - ssl_protocols: 'TLSv1.1 TLSv1.2 TLSv1.3'
              - ssl_ciphers: "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256\
                  :DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384\
                  :ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256\
                  :ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256"
              - ssl_prefer_server_ciphers: 'on'
              - resolver: 1.1.1.1
              - location /status:
                  - return: 200
              - location /:
                  - try_files: '$uri $uri/index.htm =404'
                  - error_page: '404 /jsp/error.html'
                  - rewrite: '^(/[^\.\?]+[^/])$ $1/ permanent'
