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
{% set master_pass = salt.random.get_string(42) %}
{% set master_user = 'odl-devops' %}
{% set pg_configs = env_settings.backends.postgres_rds %}

create_{{ ENVIRONMENT }}_rds_db_subnet_group:
  boto_rds.subnet_group_present:
    - name: db-subnet-group-{{VPC_RESOURCE_SUFFIX }}
    - subnet_ids: {{ subnet_ids }}
    - tags:
        Name: db-subnet-group-{{VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_{{ ENVIRONMENT }}_rds_store:
  boto_rds.present:
    - name: {{ VPC_RESOURCE_SUFFIX }}-rds-postgresql
    - allocated_storage: {{ pg_configs.allocated_storage }}
    - db_instance_class: {{ pg_configs.db_instance_class }}
    - storage_type: gp2
    - engine: postgres
    - multi_az: {{ pg_configs.multi_az }}
    - auto_minor_version_upgrade: True
    - publicly_accessible: False
    - master_username: {{ master_user }}
    - master_user_password: {{ master_pass }}
    - vpc_security_group_ids:
        - {{ salt.boto_secgroup.get_group_id(
             'postgres-rds-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
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
    - require:
        - boto_rds: create_{{ ENVIRONMENT }}_rds_db_subnet_group

configure_vault_postgresql_backend:
  vault.secret_backend_enabled:
    - backend_type: postgresql
    - description: Backend to create dynamic PostGreSQL credentials for {{ ENVIRONMENT }}
    - mount_point: postgresql-{{ ENVIRONMENT }}
    - ttl_max: {{ SIX_MONTHS }}
    - ttl_default: {{ SIX_MONTHS }}
    - lease_max: {{ SIX_MONTHS }}
    - lease_default: {{ SIX_MONTHS }}
    - connection_config:
        connection_url: "postgresql://{{ master_user }}:{{ master_pass }}@{{ PURPOSE }}-db.service.consul:15432/{{ PURPOSE }}"
        verify_connection: False
