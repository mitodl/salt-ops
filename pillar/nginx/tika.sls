{% set app_name = 'tika' %}
{% set server_domain_name = 'tika-{}.odl.mit.edu'.format(salt.grains.get('environment')) %}
{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set access_token = salt.vault.read('secret-operations/{}/tika/access-token'.format(ENVIRONMENT)).data.value %}

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
          - server:
              - server_name: {{ server_domain_name }}
              - listen: '443 ssl'
              - listen: '[::]:443 ssl'
              - ssl_certificate: /etc/nginx/ssl/odl.mit.edu.crt
              - ssl_certificate_key: /etc/nginx/ssl/odl.mit.edu.key
              - ssl_stapling: 'on'
              - ssl_stapling_verify: 'on'
              - ssl_session_timeout: 1d
              - ssl_protocols: 'TLSv1.2 TLSv1.3'
              - ssl_ciphers: "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305\
                   :ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256\
                   :ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256"
              - ssl_prefer_server_ciphers: 'on'
              - resolver: 1.1.1.1
              - location /status:
                      - return: 200
              - location /:
                  - 'if ($http_x_access_token != {{ access_token }})':
                      - return: 403
                  - proxy_pass: http://127.0.0.1:9998
                  - proxy_set_header: Host $http_host
                  - proxy_http_version: 1.1
                  - proxy_set_header: X-Forwarded-For $remote_addr
                  - proxy_pass_header: Server
