{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}

elastic_stack:
  version: 6.8.14
  elasticsearch:
    configuration_settings:
      discovery:
        zen.hosts_provider: ec2
      discovery.zen.minimum_master_nodes: 2
      gateway.recover_after_nodes: 2
      gateway.expected_nodes: 3
      gateway.recover_after_time: 5m
      rest.action.multi.allow_explicit_index: false
      xpack.security.enabled: false
      xpack.monitoring.collection.enabled: false
      xpack.ml.enabled: false
    plugins:
      - name: discovery-ec2
        config:
          aws:
            region: us-east-1
      - name: readonlyrest
        location: https://raw.githubusercontent.com/mitodl/salt-ops/master/salt/artifacts/readonlyrest-1.28.2_es6.8.14.zip
    plugin_settings:
      readonlyrest:
        readonlyrest:
          enable: 'true'
          response_if_req_forbidden: Acess Denied
          access_control_rules:
            - name: All APIs from localhost
              type: allow
              actions:
                - 'cluster:*'
                - 'indices:*'
                - 'internal:*'
              hosts_local:
                - '127.0.0.1'
            - name: Cluster access within VPC
              type: allow
              actions:
                - 'cluster:*'
              hosts:
                - {{ env_data.network_prefix }}.0.0/16
              x_forwarded_for:
                - {{ env_data.network_prefix }}.0.0/16
            - name: Access for micromasters production index with HTTP Auth
              type: allow
              indices:
                - micromasters
                - 'micromasters_*'
              actions:
                - 'indices:*'
              auth_key: __vault__::secret-micromasters/production/elasticsearch-auth-key>data>value
            - name: Access for micromasters RC index with HTTP Auth
              type: allow
              indices:
                - 'micromasters-rc*'
              actions:
                - 'indices:*'
              auth_key: __vault__::secret-micromasters/rc/elasticsearch-auth-key>data>value
            - name: Access for micromasters CI index with HTTP Auth
              type: allow
              indices:
                - 'micromasters-ci*'
              actions:
                - 'indices:*'
              auth_key: __vault__::secret-micromasters/ci/elasticsearch-auth-key>data>value
            - name: View existence of Micromasters indices with RC Auth
              type: allow
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
                - 'indices:data/read/scroll'
              auth_key: __vault__::secret-micromasters/rc/elasticsearch-auth-key>data>value
            - name: View existence of Micromasters indices with CI Auth
              type: allow
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
                - 'indices:data/read/scroll'
              auth_key: __vault__::secret-micromasters/ci/elasticsearch-auth-key>data>value
            - name: View existence of Micromasters indices with Production Auth
              type: allow
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
                - 'indices:data/read/scroll'
              auth_key: __vault__::secret-micromasters/production/elasticsearch-auth-key>data>value
            - name: Access for discussions production index with HTTP Auth
              type: allow
              indices:
                - discussions
                - 'discussions_*'
              actions:
                - 'indices:*'
              auth_key: __vault__::secret-operations/production-apps/discussions/elasticsearch-auth-key>data>value
            - name: Access for discussions RC index with HTTP Auth
              type: allow
              indices:
                - 'discussions-rc*'
              actions:
                - 'indices:*'
              auth_key: __vault__::secret-operations/rc-apps/discussions/elasticsearch-auth-key>data>value
            - name: Guest user access for discussions RC index with HTTP Auth
              type: allow
              indices:
                - 'discussions-rc*'
              methods:
                - GET
              actions:
                - 'indices:*'
              auth_key: __vault__::secret-operations/rc-apps/discussions/elasticsearch-guest-user-auth-key>data>value
            - name: Access for discussions CI index with HTTP Auth
              type: allow
              indices:
                - 'discussions-ci*'
              actions:
                - 'indices:*'
              auth_key: __vault__::secret-operations/ci/discussions/elasticsearch-auth-key>data>value
            - name: View existence of indices with RC Auth
              type: allow
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
