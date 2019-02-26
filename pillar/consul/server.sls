{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set wan_nodes = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='consul-operations-*',
    fun='grains.item',
    tgt_type='glob').items() %}
{% do wan_nodes.append('{0}'.format(addr['ec2:local_ipv4'])) %}
{% endfor %}

consul:
  extra_configs:
    defaults:
      enable_syslog: True
      server: True
      skip_leave_on_interrupt: True
      rejoin_after_leave: True
      leave_on_terminate: False
      dns_config:
        allow_stale: True
        node_ttl: 30s
        service_ttl:
          "*": 30s
      telemetry:
        dogstatsd_addr: 127.0.0.1:8125
      bootstrap_expect: 3
      client_addr: 0.0.0.0
      addresses:
        dns: 0.0.0.0
        http: 0.0.0.0
      retry_join_wan: {{ wan_nodes|tojson }}
      acl_datacenter: {{ ENVIRONMENT }}
      acl_master_token: __vault__::secret-operations/{{ ENVIRONMENT }}/consul-acl-master-token>data>value
    aws_services:
      services:
        {% for dbconfig in env_data.backends.get('rds', []) %}
        {% set rds_endpoint = salt.boto_rds.get_endpoint('{env}-rds-{engine}-{db}'.format(env=ENVIRONMENT, engine=dbconfig.engine, db=dbconfig.name)) %}
        {% if rds_endpoint %}
        {% set service_name = dbconfig.pop('service_name', dbconfig.engine ~ '-' ~ dbconfig.name) %}
        - name: {{ service_name }}
          port: {{ rds_endpoint.split(':')[1] }}
          address: {{ rds_endpoint.split(':')[0] }}
          check:
            tcp: '{{ rds_endpoint }}'
            interval: 10s
        {% endif %}
        {% endfor %}
        {% for cache_config in env_data.backends.elasticache %}
        {% if cache_config.engine == 'memcached' %}
        {% set cache_data = salt.boto3_elasticache.describe_cache_clusters(cache_config.cluster_id) %}
        {% else %}
        {% set cache_data = salt.boto3_elasticache.describe_replication_groups(cache_config.cluster_id) %}
        {% endif %}
        {% if cache_data %}
        {% if cache_data[0].get('ConfigurationEndpoint') %}
        {% set endpoint = cache_data[0].ConfigurationEndpoint %}
        {% else %}
        {% set endpoint = cache_data[0].NodeGroups[0].PrimaryEndpoint %}
        {% endif %}
        - name: {{ cache_config.cluster_id }}
          port: {{ endpoint.Port }}
          address: {{ endpoint.Address }}
          check:
            tcp: '{{ endpoint.Address }}:{{ endpoint.Port }}'
            interval: 10s
        {% endif %}
        {% endfor %}
