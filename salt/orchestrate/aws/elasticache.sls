{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'rc-apps') %}
{% set env_data = salt.file.read(salt.cp.cache_file("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml"))|load_yaml %}
{% set env_settings = env_data.environments[ENVIRONMENT] %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', env_settings.vpc_name) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_settings.business_unit) %}

{% set network_prefix = env_settings.network_prefix %}
{% set SUBNETS_CIDR = '{}.0.0/22'.format(network_prefix) %}

{% set cache_configs = env_settings.backends.elasticache %}
{% if cache_configs is mapping %}
  {% set cache_configs = [cache_configs] %}
{% endif %}
{% set default_port = {
    'redis': 6379,
    'memcached': 11211
} %}

create_{{ ENVIRONMENT }}_elasticache_security_group:
  boto_secgroup.present:
    - name: elasticache-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for Elasticache servers
    - rules:
        {% for engine, port in default_port.items() %}
        - ip_protocol: tcp
          from_port: {{ port }}
          to_port: {{ port }}
          cidr_ip:
            - {{ SUBNETS_CIDR }}
        {% endfor %}
    - tags:
        Name: elasticache-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_{{ ENVIRONMENT }}_elasticache_subnet_group:
  boto3_elasticache.cache_subnet_group_present:
    - name: elasticache-subnet-group-{{ ENVIRONMENT }}
    - subnets:
        - public1-{{ ENVIRONMENT }}
        - public2-{{ ENVIRONMENT }}
        - public3-{{ ENVIRONMENT }}
    - CacheSubnetGroupDescription: Subnet group for {{ ENVIRONMENT }} elasticache clusters

{% for cache_config in cache_configs %}
{% set cache_purpose = cache_config.get('purpose', 'shared') %}
{% set BUSINESS_UNIT = cache_config.get('business_unit', BUSINESS_UNIT) %}
{% set name = '{}-{}-{}'.format(cache_config.engine, cache_purpose, ENVIRONMENT) %}
{% if cache_config.engine == 'redis' %}
create_{{ ENVIRONMENT }}_elasticache_{{ cache_config.engine }}_replication_group_{{ cache_purpose }}:
  boto3_elasticache.replication_group_present:
    - ReplicationGroupId: {{ cache_config.cluster_id[:20].strip('-') }}
    - CacheParameterGroupName: {{ cache_config.get('parameter_group_name', 'default.redis3.2.cluster.on') }}
    - ReplicationGroupDescription: Redis cluster in {{ ENVIRONMENT }} for {{ cache_purpose }} usage
    - NumNodeGroups: {{ cache_config.get('num_shards', 1) }}
    - ReplicasPerNodeGroup: {{ cache_config.get('num_replicas', 1) }}
    - AutomaticFailoverEnabled: {{ cache_config.get('failover_enabled', True) }}
{% else %}
create_{{ ENVIRONMENT }}_elasticache_{{ cache_config.engine }}_cluster_{{ cache_purpose }}:
  boto3_elasticache.cache_cluster_present:
    - CacheClusterId: {{ cache_config.cluster_id[:20].strip('-') }}
    - NumCacheNodes: {{ cache_config.get('num_cache_nodes', 2) }}
    - AZMode: {{ 'cross-az' if cache_config.get('num_cache_nodes', 2) > 1 else 'single-az' }}
{% endif %}
    - CacheNodeType: {{ cache_config.node_type }}
    - CacheSubnetGroupName: elasticache-subnet-group-{{ ENVIRONMENT }}
    - Engine: {{ cache_config.engine }}
    - EngineVersion: {{ cache_config.engine_version }}
    - Port: {{ default_port[cache_config.engine] }}
    - name: {{ name }}
    - security_groups:
        - elasticache-{{ ENVIRONMENT }}
    - Tags:
        - Key: Name
          Value: {{ name }}
        - Key: business_unit
          Value: {{ BUSINESS_UNIT }}
        - Key: Department
          Value: {{ BUSINESS_UNIT }}
        - Key: OU
          Value: {{ BUSINESS_UNIT }}
        - Key: Environment
          Value: {{ ENVIRONMENT }}
        - Key: Purpose
          Value: {{ cache_purpose }}
{% endfor %}
