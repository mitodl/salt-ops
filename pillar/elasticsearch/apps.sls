{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}

elasticsearch:
  lookup:
    configuration_settings:
      rest.action.multi.allow_explicit_index: 'false'
  plugins:
    - name: discovery-ec2
    - name: readonlyrest
      location: https://raw.githubusercontent.com/mitodl/salt-ops/master/salt/artifacts/readonlyrest-1.16.19_es6.2.4.zip
  plugin_settings:
    readonlyrest:
      readonlyrest:
        enable: 'true'
        response_if_req_forbidden: Acess Denied
        access_control_rules:
          - name: Cluster access within VPC
            type: allow
            accept_x-forwarded-for_header: 'true'
            actions:
              - 'cluster:*'
            hosts:
              - localhost
              - 127.0.0.1
              - {{ env_data.network_prefix }}.0.0/16
          - name: Access for discussions production index with HTTP Auth
            type: allow
            indices:
              - discussions
              - 'discussions_*'
            accept_x-forwarded-for_header: 'true'
            actions:
              - 'indices:*'
            auth_key: __vault__::secret-operations/production-apps/discussions/elasticsearch-auth-key>data>value
          - name: Access for discussions RC index with HTTP Auth
            type: allow
            indices:
              - 'discussions-rc*'
            accept_x-forwarded-for_header: 'true'
            actions:
              - 'indices:*'
            auth_key: __vault__::secret-operations/rc-apps/discussions/elasticsearch-auth-key>data>value
          - name: Access for discussions CI index with HTTP Auth
            type: allow
            indices:
              - 'discussions-ci*'
            accept_x-forwarded-for_header: 'true'
            actions:
              - 'indices:*'
            auth_key: __vault__::secret-operations/ci/discussions/elasticsearch-auth-key>data>value
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
              - 'discussions*'
            actions:
              - 'indices:admin/get'
              - 'indices:admin/exists'
              - 'indices:admin/refresh[s]'
              - 'indices:data/read/scroll'
            auth_key: __vault__::secret-operations/rc-apps/discussions/elasticsearch-auth-key>data>value
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
              - 'discussions*'
            actions:
              - 'indices:admin/get'
              - 'indices:admin/exists'
              - 'indices:admin/refresh[s]'
              - 'indices:data/read/scroll'
            auth_key: __vault__::secret-operations/ci/discussions/elasticsearch-auth-key>data>value
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
              - 'discussions*'
            actions:
              - 'indices:admin/get'
              - 'indices:admin/exists'
              - 'indices:admin/refresh[s]'
              - 'indices:data/read/scroll'
            auth_key: __vault__::secret-operations/production-apps/discussions/elasticsearch-auth-key>data>value
