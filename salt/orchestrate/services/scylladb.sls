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
{% set release_id = salt.sdb.get('sdb://consul/' ~ app_name ~ '/' ~ ENVIRONMENT ~ '/release-id')|default('v1') %}
{% set target_string = app_name ~ '-' ~ ENVIRONMENT ~ '-*-' ~ release_id %}

load_scylladb_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/scylladb.conf
    - source: salt://orchestrate/aws/cloud_profiles/scylladb.conf
    - template: jinja

ensure_instance_profile_exists_for_edx:
  boto_iam_role.present:
    - name: scylladb-instance-role

write_out_scylla_userdata_file:
  file.managed:
    - name: /etc/salt/cloud.d/scylladb_userdata.yml
    - contents: >-
        --clustername {{ ENVIRONMENT }}
        --total-nodes {{ INSTANCE_COUNT }}
    - makedirs: True

generate_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_scylladb_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        num_instances: {{ INSTANCE_COUNT }}
        service_name: scylladb
        release_id: {{ release_id }}
        tags:
          business_unit: {{ BUSINESS_UNIT }}
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
        environment_name: {{ ENVIRONMENT }}
        roles:
          - scylladb
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'scylladb-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids|tojson }}
        profile_overrides:
          userdata_file: '/etc/salt/cloud.d/edx_userdata.yml'
    - require:
        - file: load_scylladb_cloud_profile

deploy_scylladb_nodes:
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_scylladb_map.yml
    - kwargs:
        parallel: True
    - require:
        - file: generate_cloud_map_file

create_dummy_raid_device:
  salt.function:
    - tgt: {{ target_string }}
    - name: state.single
    - arg:
        - raid.present
    - kwarg:
        name: /dev/md0
        level: 0
        devices:
          - /dev/xvdb
        force: True

format_data_drive:
  salt.function:
    - tgt: {{ target_string }}
    - name: state.single
    - arg:
        - blockdev.formatted
    - kwarg:
        name: /dev/md0
        fs_type: xfs
    - require:
        - salt: deploy_scylladb_nodes

mount_data_drive:
  salt.function:
    - tgt: {{ target_string }}
    - name: state.single
    - arg:
        - mount.mounted
    - kwarg:
        name: /var/lib/scylla
        device: /dev/md0
        fstype: xfs
        mkmnt: True
    - require:
        - salt: format_data_drive

sync_external_modules_for_scylladb_nodes:
  salt.function:
    - name: saltutil.sync_all
    - tgt: {{ target_string }}

load_pillar_data_on_{{ ENVIRONMENT }}_scylladb_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: {{ target_string }}
    - require:
        - salt: deploy_scylladb_nodes

populate_mine_with_{{ ENVIRONMENT }}_scylladb_data:
  salt.function:
    - name: mine.update
    - tgt: {{ target_string }}
    - require:
        - salt: load_pillar_data_on_{{ ENVIRONMENT }}_scylladb_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_{{ ENVIRONMENT }}_scylladb_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: {{ target_string }}
    - require:
        - salt: populate_mine_with_{{ ENVIRONMENT }}_scylladb_data

build_{{ ENVIRONMENT }}_scylladb_nodes:
  salt.state:
    - tgt: {{ target_string }}
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_{{ ENVIRONMENT }}_scylladb_nodes

# set_authentication_data_replication_factor:
#   salt.function:
#     - name: cassandra_cql.cql_query_with_prepare
#     - tgt: 'G@roles:scylladb and G@environment:{{ ENVIRONMENT }}'
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

# create_scylla_admin_user:
#   salt.function:
#     - name: cassandra_cql.cql_query_with_prepare
#     - tgt: 'G@roles:scylladb and G@environment:{{ ENVIRONMENT }}'
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
#     - description: Backend to create dynamic Cassandra/Scylla credentials for {{ ENVIRONMENT }}
#     - mount_point: scylladb-{{ ENVIRONMENT }}
#     - ttl_max: {{ SIX_MONTHS }}
#     - ttl_default: {{ SIX_MONTHS }}
#     - lease_max: {{ SIX_MONTHS }}
#     - lease_default: {{ SIX_MONTHS }}
#     - connection_config:
#         uri: 
#         verify_connection: False
