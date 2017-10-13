{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'rc-apps') %}
{% set env_settings = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}

{% set cache_configs = env_settings.backends.elasticache %}
{% if cache_configs is mapping %}
  {% set cache_configs = [cache_configs] %}
{% endif %}

{% for cache_config in cache_configs %}
{% set cache_purpose = cache_config.get('purpose', 'shared') %}
{% if 'reddit' in cache_purpose %}
{% set name = '{}-{}-{}'.format(cache_config.engine, cache_purpose, ENVIRONMENT) %}
{% if cache_config.engine == 'redis' %}
destroy_{{ ENVIRONMENT }}_elasticache_{{ cache_config.engine }}_replication_group_{{ cache_purpose }}:
  boto3_elasticache.replication_group_absent:
    - ReplicationGroupId: {{ '{}-{}'.format(cache_purpose, cache_config.engine)[:20].strip('-') }}
    - RetainPrimaryCluster: False
{% else %}
destroy_{{ ENVIRONMENT }}_elasticache_{{ cache_config.engine }}_cluster_{{ cache_purpose }}:
  boto3_elasticache.cache_cluster_absent:
    - CacheClusterId: {{ '{}-{}'.format(cache_purpose, cache_config.engine)[:20].strip('-') }}
{% endif %}
    - name: {{ name }}
{% endif %}
{% endfor %}

{% set pg_configs = env_settings.backends.postgres_rds %}
{% set ISO8601 = '%Y-%m-%dT%H%M%S' %}
{% for dbconfig in pg_configs %}
{% if 'reddit' in dbconfig.name %}
unmount_vault_postgresql_{{ dbconfig.name }}_backend:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: vault.delete
    - arg:
        - sys/mounts/postgresql-{{ ENVIRONMENT }}-{{ dbconfig.name }}

destroy_{{ ENVIRONMENT }}_{{ dbconfig.name }}_rds_store:
  boto_rds.absent:
    - name: {{ ENVIRONMENT }}-rds-postgresql-{{ dbconfig.name }}
    - wait_for_deletion: False
    - final_db_snapshot_identifier: {{ dbconfig.name }}-{{ ENVIRONMENT }}-final-snapshot-{{ salt.status.time(format=ISO8601) }}
    - require:
        - salt: unmount_vault_postgresql_{{ dbconfig.name }}_backend
{% endif %}
{% endfor %}

{% set cassandra_instances = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:cassandra and G@environment:{}'.format(ENVIRONMENT),
    fun='grains.item',
    tgt_type='compound').items() %}
{% do cassandra_instances.append('{0}'.format(host)) %}
{% endfor %}

{% set reddit_instances = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:reddit and G@environment:{}'.format(ENVIRONMENT),
    fun='grains.item',
    tgt_type='compound').items() %}
{% do reddit_instances.append('{0}'.format(host)) %}
{% endfor %}

{% for minion in cassandra_instances %}
destroy_cassandra_instances_{{ minion }}_in_{{ ENVIRONMENT }}:
  cloud.absent:
    - name: {{ minion }}
{% endfor %}

{% for minion in reddit_instances %}
destroy_reddit_instance_{{ minion }}_in_{{ ENVIRONMENT }}:
  cloud.absent:
    - name: {{ minion }}
{% endfor %}
