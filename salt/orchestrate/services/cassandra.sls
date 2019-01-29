{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'rc-apps') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set VPC_NAME = env_data.vpc_name %}
{% set INSTANCE_COUNT = salt.environ.get('INSTANCE_COUNT', 3) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}
{% set launch_date = salt.status.time(format="%Y-%m-%d") %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|map(attribute='id')|list %}

load_cassandra_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/cassandra.conf
    - source: salt://orchestrate/aws/cloud_profiles/cassandra.conf
    - template: jinja

ensure_instance_profile_exists_for_edx:
  boto_iam_role.present:
    - name: cassandra-instance-role

generate_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_cassandra_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        num_instances: {{ INSTANCE_COUNT }}
        service_name: cassandra
        tags:
          business_unit: {{ BUSINESS_UNIT }}
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
        environment_name: {{ ENVIRONMENT }}
        roles:
          - cassandra
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'scylladb-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids }}
    - require:
        - file: load_cassandra_cloud_profile

deploy_cassandra_nodes:
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_cassandra_map.yml
    - kwargs:
        parallel: True
    - require:
        - file: generate_cloud_map_file

format_data_drive:
  salt.function:
    - tgt: 'G@roles:cassandra and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - blockdev.formatted
    - kwarg:
        name: /dev/xvdb
        fs_type: ext4
    - require:
        - salt: deploy_cassandra_nodes

mount_data_drive:
  salt.function:
    - tgt: 'G@roles:cassandra and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - mount.mounted
    - kwarg:
        name: /var/lib/cassandra
        device: /dev/xvdb
        fstype: ext4
        mkmnt: True
        opts: 'relatime,user'
    - require:
        - salt: format_data_drive

sync_external_modules_for_cassandra_nodes:
  salt.function:
    - name: saltutil.sync_all
    - tgt: 'G@roles:cassandra and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound

load_pillar_data_on_{{ ENVIRONMENT }}_cassandra_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:cassandra and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: deploy_cassandra_nodes

populate_mine_with_{{ ENVIRONMENT }}_cassandra_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:cassandra and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_{{ ENVIRONMENT }}_cassandra_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_{{ ENVIRONMENT }}_cassandra_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:cassandra and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_{{ ENVIRONMENT }}_cassandra_data

build_{{ ENVIRONMENT }}_cassandra_nodes:
  salt.state:
    - tgt: 'G@roles:cassandra and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_{{ ENVIRONMENT }}_cassandra_nodes

# set_authentication_data_replication_factor:
#   salt.function:
#     - name: cassandra_cql.cql_query_with_prepare
#     - tgt: 'G@roles:cassandra and G@environment:{{ ENVIRONMENT }}'
#     - tgt_type: compound
#     - subset: 1
#     - kwarg:
#         statement_name: password_replication
#         query: >-
#            ALTER KEYSPACE system_auth WITH REPLICATION =
#            { 'class' : 'SimpleStrategy', 'replication_factor' : ? };
#         statement_arguments: {{ INSTANCE_COUNT }}
#         cql_user: cassandra
#         cql_pass: cassandra

# create_cassandra_admin_user:
#   salt.function:
#     - name: cassandra_cql.cql_query_with_prepare
#     - tgt: 'G@roles:cassandra and G@environment:{{ ENVIRONMENT }}'
#     - tgt_type: compound
#     - subset: 1
#     - kwarg:
#         statement_name: password_replication
#         query: >-
#            CREATE ROLE odldevops WITH SUPERUSER = true AND LOGIN = true
#            AND PASSWORD = '?';
#         statement_arguments: {{ INSTANCE_COUNT }}
#         cql_user: cassandra
#         cql_pass: cassandra

# configure_vault_cassandra_backend:
#   vault.secret_backend_enabled:
#     - backend_type: cassandra
#     - description: Backend to create dynamic Cassandra/ScyllaDB credentials for {{ ENVIRONMENT }}
#     - mount_point: cassandra-{{ ENVIRONMENT }}
#     - ttl_max: {{ SIX_MONTHS }}
#     - ttl_default: {{ SIX_MONTHS }}
#     - lease_max: {{ SIX_MONTHS }}
#     - lease_default: {{ SIX_MONTHS }}
#     - connection_config:
#         uri: 
#         verify_connection: False
