{% set production_auth_key = salt.vault.read('secret-micromasters/production/elasticsearch-auth-key').data.value %}
{% set rc_auth_key = salt.vault.read('secret-micromasters/rc/elasticsearch-auth-key').data.value %}
{% set ci_auth_key = salt.vault.read('secret-micromasters/ci/elasticsearch-auth-key').data.value %}
{% set odl_wildcard_cert = salt.vault.read('secret-operations/global/odl_wildcard_cert') %}
{% set dhparam = salt.vault.read('secret-micromasters/production/dhparam').data.value %}

elasticsearch:
  lookup:
    configuration_settings:
      cluster.name: micromasters
      discover.ec2.tag.escluster: micromasters
      rest.action.multi.allow_explicit_index: 'false'
      readonlyrest:
        enable: 'true'
        response_if_req_forbidden: Acess Denied
        access_control_rules:
          - name: Cluster access within VPC
            type: allow
            accept_x-forwarded-for_header: 'true'
            indices:
              - <no-index>
            actions:
              - 'cluster:*'
            hosts:
              - localhost
              - 127.0.0.1
              - 10.10.0.0/16
          - name: Access for micromasters production index with HTTP Auth
            type: allow
            indices:
              - micromasters
              - 'micromasters_*'
            accept_x-forwarded-for_header: 'true'
            actions:
              - 'indices:*'
            auth_key: {{ production_auth_key }}
          - name: Access for micromasters RC index with HTTP Auth
            type: allow
            indices:
              - 'micromasters-rc*'
            accept_x-forwarded-for_header: 'true'
            actions:
              - 'indices:*'
            auth_key: {{ rc_auth_key }}
          - name: Access for micromasters CI index with HTTP Auth
            type: allow
            indices:
              - 'micromasters-ci*'
            accept_x-forwarded-for_header: 'true'
            actions:
              - 'indices:*'
            auth_key: {{ ci_auth_key }}
          - name: View existence of indices with RC Auth
            type: allow
            accept_x-forwarded-for_header: 'true'
            methods:
              - GET
              - HEAD
              - OPTIONS
              - POST
            indices:
              - '_all'
              - 'micromasters*'
            actions:
              - 'indices:admin/get'
              - 'indices:admin/exists'
              - 'indices:admin/refresh[s]'
            auth_key: {{ rc_auth_key }}
          - name: View existence of indices with CI Auth
            type: allow
            accept_x-forwarded-for_header: 'true'
            methods:
              - GET
              - HEAD
              - OPTIONS
              - POST
            indices:
              - '_all'
              - 'micromasters*'
            actions:
              - 'indices:admin/get'
              - 'indices:admin/exists'
              - 'indices:admin/refresh[s]'
            auth_key: {{ ci_auth_key }}
          - name: View existence of indices with Production Auth
            type: allow
            accept_x-forwarded-for_header: 'true'
            methods:
              - GET
              - HEAD
              - OPTIONS
              - POST
            indices:
              - '_all'
              - 'micromasters*'
            actions:
              - 'indices:admin/get'
              - 'indices:admin/exists'
              - 'indices:admin/refresh[s]'
            auth_key: {{ production_auth_key }}
      repositories:
        s3:
          bucket: micromasters-elasticsearch-backups
          region: us-east-1
    products:
      elasticsearch: '2.x'
  plugins:
    - name: cloud-aws
    - name: elasticsearch-readonlyrest
      location: https://github.com/sscarduzio/elasticsearch-readonlyrest-plugin/archive/v1.14.0_es2.4.1.zip

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
