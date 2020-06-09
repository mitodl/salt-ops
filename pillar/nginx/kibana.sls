{% set app_name = 'kibana' %}
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set server_domain_names = env_data.purposes[app_name].domains %}

nginx:
  install_from_repo: True
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
      {{ app_name }}:
        enabled: True
        config:
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
              - ssl_certificate: /etc/nginx/ssl/odl.mit.edu.crt
              - ssl_certificate_key: /etc/nginx/ssl/odl.mit.edu.key
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
                  - proxy_pass: http://localhost:5601/
                  - proxy_set_header: 'Host $host'
                  - proxy_set_header: 'X-Real-IP $remote_addr'
                  - proxy_set_header: 'X-Forwarded-For $proxy_add_x_forwarded_for'
                  - proxy_headers_hash_bucket_size: 128
                  - proxy_read_timeout: 240s
              {% if 'operations-qa' not in ENVIRONMENT %}
              - ssl_client_certificate: /etc/ssl/certs/mitca.pem
              - ssl_verify_client: 'on'
              - set $authorized: 'no'
              - if ($ssl_client_s_dn ~ "emailAddress=(tmacey|pdpinch|shaidar|ichuang|gsidebo|mkdavies|gschneel|mattbert|nlevesq|ferdial|maxliu|annagav|mbrdlove|jmartis|abeglova|gumaerc)@MIT.EDU"):
                - set $authorized: 'yes'
              - if ($authorized !~ "yes"):
                - return: 403
              {% endif %}
