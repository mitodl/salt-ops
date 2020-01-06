{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}

nginx:
  server:
    config:
      http:
        access_log: !!null
  dh_param:
    dhparam.pem: __vault__::secret-operations/{{ ENVIRONMENT }}/dhparam>data>value
  certificates:
    apps-es:
      public_cert: __vault__::secret-operations/global/odl_wildcard_cert>data>value
      private_key: __vault__::secret-operations/global/odl_wildcard_cert>data>key
  servers:
    managed:
      elasticsearch:
        enabled: True
        config:
          - server:
              - server_name: elasticsearch-{{ ENVIRONMENT }}.odl.mit.edu
              - listen: '443 ssl'
              - listen: '[::]:443 ssl'
              - location ~ ^/(_alias|_aliases|discussions|micromasters|_refresh|_mapping):
                  - proxy_pass: http://127.0.0.1:9200$request_uri
                  - proxy_set_header: 'X-Forwarded-For $proxy_add_x_forwarded_for'
                  - proxy_pass_header: 'X-Api-Key'
                  - client_max_body_size: '20m'
              - location /_search/scroll:
                  - proxy_pass: http://127.0.0.1:9200$request_uri
                  - proxy_set_header: 'X-Forwarded-For $proxy_add_x_forwarded_for'
                  - proxy_pass_header: 'X-Api-Key'
              - location /nginx_status:
                  - stub_status: 'on'
                  - allow: 127.0.0.1
                  - deny: all
              - ssl_certificate: /etc/nginx/ssl/apps-es.crt
              - ssl_certificate_key: /etc/nginx/ssl/apps-es.key
              - ssl_dhparam: /etc/nginx/ssl/dhparam.pem
              - ssl_stapling: 'on'
              - ssl_stapling_verify: 'on'
              - ssl_session_timeout: 1d
              - ssl_session_tickets: 'off'
              - ssl_protocols:
                  - TLSv1.2
              - ssl_ciphers: 'TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256'
              - ssl_prefer_server_ciphers: 'on'
              - resolver: 8.8.8.8
