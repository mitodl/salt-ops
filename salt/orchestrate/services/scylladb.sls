{% from "orchestrate/aws_env_macro.jinja" import VPC_NAME, VPC_RESOURCE_SUFFIX,
 ENVIRONMENT, BUSINESS_UNIT, subnet_ids with context %}
{% set INSTANCE_COUNT = salt.environ.get('INSTANCE_COUNT', 3) %}
{% set scylla_admin_password = salt.random.get_str(42) %}
{% set SIX_MONTHS = '4368h' %}

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
    - name: /etc/salt/cloud.maps.d/{{ VPC_RESOURCE_SUFFIX }}_scylladb_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        num_instances: {{ INSTANCE_COUNT }}
        service_name: scylladb
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
        subnetids: {{ subnet_ids }}
        profile_overrides:
          userdata_file: '/etc/salt/cloud.d/edx_userdata.yml'
    - require:
        - file: load_scylladb_cloud_profile

deploy_scylladb_nodes:
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ VPC_RESOURCE_SUFFIX }}_scylladb_map.yml
    - kwargs:
        parallel: True
    - require:
        - file: generate_cloud_map_file

format_data_drive:
  salt.function:
    - tgt: 'G@roles:scylladb and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - blockdev.formatted
    - kwarg:
        name: /dev/xvdb
        fs_type: xfs
    - require:
        - salt: deploy_scylladb_nodes

mount_data_drive:
  salt.function:
    - tgt: 'G@roles:scylladb and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - mount.mounted
    - kwarg:
        name: /var/lib/scylla
        device: /dev/xvdb
        fstype: xfs
        mkmnt: True
        opts: 'relatime,user'
    - require:
        - salt: format_data_drive

sync_external_modules_for_scylladb_nodes:
  salt.function:
    - name: saltutil.sync_all
    - tgt: 'G@roles:scylladb and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound

load_pillar_data_on_{{ ENVIRONMENT }}_scylladb_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:scylladb and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: deploy_scylladb_nodes

populate_mine_with_{{ ENVIRONMENT }}_scylladb_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:scylladb and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_{{ ENVIRONMENT }}_scylladb_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_{{ ENVIRONMENT }}_scylladb_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:scylladb and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_{{ ENVIRONMENT }}_scylladb_data

build_{{ ENVIRONMENT }}_scylladb_nodes:
  salt.state:
    - tgt: 'G@roles:scylladb and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
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
