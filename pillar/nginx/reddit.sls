{% set server_domain_name = 'discussions-reddit-{}.odl.mit.edu'.format(salt.grains.get('environment')) %}
{% set ENVIRONMENT = salt.grains.get('environment') %}

reddit:
  api_access_token: __vault__::secret-operations/{{ ENVIRONMENT }}/reddit/access-token>data>value

nginx:
  ng:
    install_from_ppa: True
    certificates:
      odl.mit.edu:
        public_cert: __vault__::secret-operations/global/odl_wildcard_cert>data>value
        private_key: __vault__::secret-operations/global/odl_wildcard_cert>data>key
    servers:
      managed:
        default:
          enabled: False
          deleted: True
          config: None
        reddit:
          enabled: True
          config:
            - map $http_upgrade $connection_upgrade:
                - default: upgrade
                - "''": close
            - server:
                - server_name: {{ server_domain_name }}
                - listen:
                    - 443
                    - ssl
                - listen:
                    - '[::]:443'
                    - ssl
                - ssl_certificate: /etc/nginx/ssl/odl.mit.edu.crt
                - ssl_certificate_key: /etc/nginx/ssl/odl.mit.edu.key
                - ssl_stapling: 'on'
                - ssl_stapling_verify: 'on'
                - ssl_session_timeout: 1d
                - ssl_protocols:
                    - TLSv1.2
                - ssl_ciphers: "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256\
                     :ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384\
                     :DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256\
                     :ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384\
                     :ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256\
                     :DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256\
                     :AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS"
                - ssl_prefer_server_ciphers: 'on'
                - resolver: 8.8.8.8
                - location /:
                    - 'if ($http_x_access_token != {{ access_token }})':
                        - return: 403
                    - proxy_pass: http://127.0.0.1:8001
                    - proxy_set_header: Host $http_host
                    - proxy_http_version: 1.1
                    - proxy_set_header: X-Forwarded-For $remote_addr
                    - proxy_pass_header: Server
                    {# allow websockets through if desired #}
                    - proxy_set_header: Upgrade $http_upgrade
                    - proxy_set_header: Connection $connection_upgrade
                - location /media/:
                    - expires: max
                    - alias: /var/www/media/
                - location /heartbeat:
                    - return: 200
