{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set env_settings = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', env_settings.vpc_name) %}
{% set VPC_RESOURCE_SUFFIX = salt.environ.get(
    'VPC_RESOURCE_SUFFIX',
    VPC_NAME.lower().replace(' ', '-')) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_settings.business_unit) %}

{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-{}'.format(VPC_RESOURCE_SUFFIX),
    'public2-{}'.format(VPC_RESOURCE_SUFFIX),
    'public3-{}'.format(VPC_RESOURCE_SUFFIX)])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

{% set SIX_MONTHS = '4368h' %}
{% set master_pass = salt.random.get_str(42) %}
{% set master_user = 'odldevops' %}
{% set db_configs = env_settings.backends.rds %}

create_{{ ENVIRONMENT }}_rds_db_subnet_group:
  boto_rds.subnet_group_present:
    - name: db-subnet-group-{{VPC_RESOURCE_SUFFIX }}
    - description: Subnet group for {{ ENVIRONMENT }} RDS instances
    - subnet_ids: {{ subnet_ids }}
    - tags:
        Name: db-subnet-group-{{VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

{% for dbconfig in db_configs %}
create_{{ ENVIRONMENT }}_{{ dbconfig.name }}_rds_store:
  boto_rds.present:
    - name: {{ VPC_RESOURCE_SUFFIX }}-rds-postgresql-{{ dbconfig.name }}
    - allocated_storage: {{ dbconfig.allocated_storage }}
    - db_instance_class: {{ dbconfig.db_instance_class }}
    - db_name: {{ dbconfig.name }}
    - storage_type: gp2
    - engine: {{ dbconfig.engine }}
    - multi_az: {{ dbconfig.multi_az }}
    - auto_minor_version_upgrade: True
    - publicly_accessible: {{ dbconfig.get('public_access', False) }}
    - master_username: {{ master_user }}
    - master_user_password: {{ master_pass }}
    - vpc_security_group_ids:
        {% if dbconfig.get('public_access', False) %}
        - {{ salt.boto_secgroup.get_group_id(
             '{}-rds-public-{}'.format(dbconfig.engine, ENVIRONMENT), vpc_name=VPC_NAME) }}
        {% else %}
        - {{ salt.boto_secgroup.get_group_id(
             '{}-rds-{}'.format(dbconfig.engine, ENVIRONMENT), vpc_name=VPC_NAME) }}
        {% endif %}
        - {{ salt.boto_secgroup.get_group_id(
             'vault-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
    - db_subnet_group_name: db-subnet-group-{{ VPC_RESOURCE_SUFFIX }}
    - copy_tags_to_snapshot: True
    - tags:
        Name: {{ VPC_RESOURCE_SUFFIX }}-rds-mysql
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}
        Purpose: {{ dbconfig.get('purpose', 'shared') }}
    - require:
        - boto_rds: create_{{ ENVIRONMENT }}_rds_db_subnet_group

{% set mount_point = '{}-{}-{}'.format(dbconfig.engine, ENVIRONMENT, dbconfig.name) %}
configure_vault_postgresql_{{ dbconfig.name }}_backend:
  vault.secret_backend_enabled:
    - backend_type: database
    - description: Backend to create dynamic {{ dbconfig.engine }} credentials for {{ ENVIRONMENT }}
    - mount_point: {{ mount_point }}
    - ttl_max: {{ SIX_MONTHS }}
    - ttl_default: {{ SIX_MONTHS }}
    - lease_max: {{ SIX_MONTHS }}
    - lease_default: {{ SIX_MONTHS }}
    - connection_config_path: {{ mount_point }}/config/{{ dbconfig.name }}
    - connection_config:
        plugin_name: {{ dbconfig.vault_plugin }}
        {% if dbconfig.engine == 'postgres' %}
        connection_url: "postgresql://{{ master_user }}:{{ master_pass }}@postgresql-{{ dbconfig.name }}.service.{{ ENVIRONMENT }}.consul:5432/{{ dbconfig.name }}"
        {% else %}
        connection_url: "{{ master_user }}:{{ master_pass }}@tcp(mysql.service.{{ ENVIRONMENT }}.consul:3306)/"
        {% endif %}
        verify_connection: False
{% endfor %}
