{% set odl_wildcard_cert = salt.vault.read('secret-operations/global/odl_wildcard_cert') %}
{% set dhparam = salt.vault.read('secret-micromasters/production/dhparam').data.value %}

nginx:
  ng:
    dh_contents: |
      {{ dhparam|indent(6) }}
    certificates:
      micromasters-es:
        public_cert: |
          {{ odl_wildcard_cert.data.value|indent(10) }}
        private_key: |
          {{ odl_wildcard_cert.data.key|indent(10) }}
    servers:
      managed:
        elasticsearch:
          enabled: True
          config:
            - server:
                - server_name: micromasters-es.odl.mit.edu
                - listen:
                    - 443
                    - ssl
                - listen:
                    - '[::]:443'
                    - ssl
                - location ~ ^/(_alias|_aliases|micromasters|_refresh|_mapping):
                    - proxy_pass: http://127.0.0.1:9200$uri
                    - proxy_set_header: 'X-Forwarded-For $proxy_add_x_forwarded_for'
                    - proxy_pass_header: 'X-Api-Key'
                - location /nginx_status:
                    - stub_status: 'on'
                    - allow: 127.0.0.1
                    - deny: all
                - ssl_certificate: /etc/nginx/ssl/micromasters-es.crt
                - ssl_certificate_key: /etc/nginx/ssl/micromasters-es.key
                - ssl_dhparam: /etc/nginx/ssl/dhparam.pem
                - ssl_stapling: 'on'
                - ssl_stapling_verify: 'on'
                - ssl_session_timeout: 1d
                - ssl_session_tickets: 'off'
                - ssl_protocols:
                    - TLSv1.2
                - ssl_ciphers: 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSpA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS'
                - ssl_prefer_server_ciphers: 'on'
                - resolver: 8.8.8.8
