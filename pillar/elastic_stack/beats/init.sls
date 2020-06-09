{% set ENVIRONMENT = salt.grains.get('environment') %}

elastic_stack:
  beats:
    metricbeat:
      config:
        metricbeat.config.modules:
          path: /etc/metricbeat/modules.d/*.yml
          reload.enabled: true
          reload.period: 30s
        name: {{ grains['id'] }}
        tags:
          - {{ grains['id'] }}
          - {{ grains.get('environment') }}
          - {{ grains.get('roles')|join(',') }}
          - {{ grains.get('osfullname') }}
        processors:
          - add_cloud_metadata: ~
          - add_host_metadata: ~
        output.elasticsearch:
          {% if 'operations-qa' in ENVIRONMENT %}
          hosts:
            - https://operations-elasticsearch.query.consul:9200
          username: __vault__::secret-operations/{{ ENVIRONMENT }}/xpack/metricbeat_agent>data>user
          password: __vault__::secret-operations/{{ ENVIRONMENT }}/xpack/metricbeat_agent>data>password
          ssl.verification_mode: "none"
          {% else %}
          hosts:
            - http://operations-elasticsearch.query.consul:9200
          {% endif %}
          compression_level: 3
        setup.template.name: "metricbeat-%{[agent.version]}"
        setup.template.pattern: "metricbeat-%{[agent.version]}-*"
      modules:
        system:
          - module: system
            metricsets:
              - cpu
              - filesystem
              - load
              - memory
              - network
              - process
              - process_summary
              - uptime
            enabled: 'true'
            period: 5s
            processes:
              - '.*'
