{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set env_settings = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', env_settings.vpc_name) %}
{% set VPC_RESOURCE_SUFFIX = salt.environ.get(
    'VPC_RESOURCE_SUFFIX',
    VPC_NAME.lower().replace(' ', '-')) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_settings.business_unit) %}

{% set SIX_MONTHS = '4368h' %}
{% set master_pass = salt.random.get_string(42) %}
{% set master_user = 'odl-devops' %}
{% set cache_configs = env_settings.backends.elasticache %}
{% if cache_configs|mapping %}
  {% set cache_configs = [cache_configs] %}
{% endif %}
{% set default_port = {
    'redis': 6379,
    'memcached': 11211
} %}

create_{{ ENVIRONMENT }}_elasticache_security_group:
  boto_secgroup.present:
    - name: elasticache-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for PostGreSQL RDS servers
    - rules:
        {% for engine, port in default_port.items %}
        - ip_protocol: tcp
          from_port: {{ port }}
          to_port: {{ port }}
          cidr_ip:
            - {{ cidr_ip }}
        {% endfor %}
    - tags:
        Name: elasticache-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_{{ ENVIRONMENT }}_elasticache_subnet_group:
  boto3_elasticache.cache_subnet_group_present:
    - name: elasticache-subnet-group-{{ VPC_RESOURCE_SUFFIX }}
    - subnets:
        - public1-{{ VPC_RESOURCE_SUFFIX }}
        - public2-{{ VPC_RESOURCE_SUFFIX }}
        - public3-{{ VPC_RESOURCE_SUFFIX }}
    - region: us-east-1
    - tags:
        Name: elasticache-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

{% for cache_config in cache_configs %}
{% if cache_config.engine == 'redis' %}
create_{{ ENVIRONMENT }}_elasticache_{{ cache_config.engine }}_replication_group_{{ loop.index0 }}:
  boto3_elasticache.replication_group_present:
    - name: elasticache-{{ cache_config.engine }}-cluster-{{ VPC_RESOURCE_SUFFIX }}
    - ReplicationGroupId: {{ '{}-{}'.format(VPC_RESOURCE_SUFFIX, cache_config.engine)[:20] }}
    - CacheParameterGroupName: {{ cache_config.get('parameter_group_name', 'default.redis3.2.cluster.on') }}
    - CacheSubnetGroupName: elasticache-subnet-group-{{ VPC_RESOURCE_SUFFIX }}
    - Port: {{ default_port[cache_config.engine] }}
    - NumNodeGroups: {{ cache_config.get('num_shards', 1) }}
    - ReplicasPerNodeGroup: {{ cache_config.get('num_replicas', 1) }}
    - AutomaticFailoverEnabled: True
    - security_groups:
        - elasticache-{{ VPC_RESOURCE_SUFFIX }}
    - Tags:
        Name: elasticache-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}
{% else %}
create_{{ ENVIRONMENT }}_elasticache_{{ cache_config.engine }}_cluster_{{ loop.index0 }}:
  boto3_elasticache.cache_cluster_present:
    - name: elasticache-{{ cache_config.engine }}-{{ VPC_RESOURCE_SUFFIX }}
    - CacheClusterId: {{ '{}-{}'.format(VPC_RESOURCE_SUFFIX, cache_config.engine)[:20] }}
    - security_groups:
        - elasticache-{{ VPC_RESOURCE_SUFFIX }}
        - NumCacheNodes: {{ cache_config.get('num_cache_nodes', 2) }}
    - CacheNodeType: {{ cache_config.node_type }}
    - CacheSubnetGroupName: elasticache-subnet-group-{{ VPC_RESOURCE_SUFFIX }}
    - Port: {{ default_port[cache_config.engine] }}
    - AZMode: cross-az
    - security_groups:
        - elasticache-{{ VPC_RESOURCE_SUFFIX }}
    - Tags:
        - Key: Name
          Value: elasticache-{{ VPC_RESOURCE_SUFFIX }}
        - Key: business_unit
          Value: {{ BUSINESS_UNIT }}
        - Key: Department
          Value: {{ BUSINESS_UNIT }}
        - Key: OU
          Value: {{ BUSINESS_UNIT }}
        - Key: Environment
          Value0: {{ ENVIRONMENT }}
{% endif %}
{% endfor %}
