{% set app_name = 'starcellbio' %}
{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set server_domain_names = env_data.purposes[app_name].domains %}
{% set ovs_login_path = 'login' %}

nginx:
  install_from_ppa: True
  certificates:
    starcellbio:
      public_cert: __vault__::secret-starteam/global/starcellbio/ssl>data>cert
      private_key: __vault__::secret-starteam/global/starcellbio/ssl>data>key
  servers:
    managed:
      {{ app_name }}:
        enabled: True
        config:
          - server:
              - server_name: '{{ server_domain_names|join(' ') }} ""'
              - listen: 80
              - listen: '[::]:80'
              - location /status:
                  - return: 200 OK
                  - add_header: Content-Type text/plain
              - location /:
                  - return: 301 https://$host$request_uri
          - server:
              - server_name: '{{ server_domain_names|join(' ') }} ""'
              - listen: '443 ssl default_server'
              - listen: '[::]:443 ssl'
              - root: /opt/{{ app_name }}/
              - ssl_certificate: /etc/nginx/ssl/starcellbio.crt
              - ssl_certificate_key: /etc/nginx/ssl/starcellbio.key
              - ssl_stapling: 'on'
              - ssl_stapling_verify: 'on'
              - ssl_session_timeout: 1d
              - ssl_session_tickets: 'off'
              - ssl_protocols: 'TLSv1 TLSv1.1 TLSv1.2 TLSv1.3'
              - ssl_ciphers: "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256\
                  :DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384\
                  :ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256\
                  :ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256"
              - ssl_prefer_server_ciphers: 'on'
              - resolver: 1.1.1.1
              - location /status:
                  - return: 200 OK
                  - add_header: Content-Type text/plain
              - location /:
                  - include: uwsgi_params
                  - uwsgi_ignore_client_abort: 'on'
                  - uwsgi_pass: unix:/var/run/uwsgi/{{ app_name }}.sock
              - location ~* /static/(.*$):
                  - expires: max
                  - add_header: 'Access-Control-Allow-Origin *'
                  - try_files: '$uri $uri/ /staticfiles/$1 /staticfiles/$1/ =404'
