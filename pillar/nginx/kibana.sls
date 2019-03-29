{% set app_name = 'kibana' %}
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set server_domain_names = env_data.purposes[app_name].domains %}

nginx:
  ng:
    install_from_source: True
    source_version: 1.15.1
    source_hash: c7206858d7f832b8ef73a45c9b8f8e436bcb1ee88db2bc85b8e438ecec9d5460
    with:
      - http_ssl_module
      - pcre
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
                - server_name: {{ server_domain_names }}
                - listen:
                    - 80
                - listen:
                    - '[::]:80'
                - location /:
                    - return: 301 https://$host$request_uri
            - server:
                - server_name: {{ server_domain_names }}
                - listen:
                    - 443
                    - ssl
                    - default
                - listen:
                    - '[::]:443'
                    - ssl
                - ssl_certificate: /etc/nginx/ssl/odl.mitl.edu.crt
                - ssl_certificate_key: /etc/nginx/ssl/odl.mit.edu.key
                - ssl_stapling: 'on'
                - ssl_stapling_verify: 'on'
                - ssl_session_timeout: 1d
                - ssl_session_tickets: 'off'
                - ssl_protocols:
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
                - location /:
                    - proxy_pass: http://localhost:5601/
                    - proxy_set_header:
                      - Host
                      - $host
                    - proxy_set_header:
                      - X-Real-IP
                      - $remote_addr
                    - proxy_set_header:
                      - X-Forwarded-For__vault__::secret-operations/global/mitca_ssl_cert>data>value
                      - $remote_addr
                - ssl_client_certificate: /etc/ssl/certs/mitca.pem
                - ssl_verify_client: 'on'
                - set $authorized: 'no'
                - if ($ssl_client_s_dn ~ "/emailAddress=(tmacey|pdpinch|shaidar|ichuang|gsidebo|mkdavies|gschneel|mattbert|nlevesq|ferdial|maxliu|annagav|mbrdlove)@MIT.EDU"):
                  - set $authorized: 'yes'
                - if ($authorized !~ "yes"):
                  - return: 403
