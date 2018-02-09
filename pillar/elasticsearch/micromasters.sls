{% set production_auth_key = salt.vault.read('secret-micromasters/production/elasticsearch-auth-key').data.value %}
{% set rc_auth_key = salt.vault.read('secret-micromasters/rc/elasticsearch-auth-key').data.value %}
{% set ci_auth_key = salt.vault.read('secret-micromasters/ci/elasticsearch-auth-key').data.value %}

elasticsearch:
  lookup:
    elastic_stack: True
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
    products:
      elasticsearch: '5.x'
  plugins:
    - name: discovery-ec2
    - name: elasticsearch-readonlyrest
      location: https://raw.githubusercontent.com/mitodl/salt-ops/master/salt/artifacts/readonlyrest-1.16.15_es5.6.6.zip
