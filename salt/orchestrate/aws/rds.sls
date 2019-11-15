{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set env_dict = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set env_settings = env_dict.environments[ENVIRONMENT] %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', env_settings.vpc_name) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_settings.business_unit) %}

{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-{}'.format(ENVIRONMENT),
    'public2-{}'.format(ENVIRONMENT),
    'public3-{}'.format(ENVIRONMENT)])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

{% set SIX_MONTHS = '4368h' %}
{% set master_user = 'odldevops' %}
{% set db_configs = env_settings.backends.rds %}

create_{{ ENVIRONMENT }}_rds_db_subnet_group:
  boto_rds.subnet_group_present:
    - name: db-subnet-group-{{ENVIRONMENT }}
    - description: Subnet group for {{ ENVIRONMENT }} RDS instances
    - subnet_ids: {{ subnet_ids|tojson }}
    - tags:
        Name: db-subnet-group-{{ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

{% for dbconfig in db_configs %}

{% set name = dbconfig.pop('name') %}
{% set engine = dbconfig.pop('engine') %}
{% set db_identifier = ENVIRONMENT ~ '-rds-' ~ engine ~ '-' ~ name %}
{% set public_access = dbconfig.pop('public_access', False) %}
{% set dbpurpose = dbconfig.pop('purpose', 'shared') %}
{% set vault_plugin = dbconfig.pop('vault_plugin') %}
{% set pw_length = dbconfig.pop('password_length', 42) %}
{% set service_name = dbconfig.pop('service_name',
                                   engine ~ '-' ~ name) %}
{% set mount_point = dbconfig.pop('mount_point',
                                  '{}-{}-{}'.format(engine, ENVIRONMENT, name)) %}
{% set engine_version = dbconfig.pop('engine_version') %}
{% set replica = dbconfig.pop('replica', {}) %}
{% set custom_parameters = dbconfig.pop('parameters', {}) %}

{% set vault_master_pass_path = 'secret-' ~ BUSINESS_UNIT ~ '/' ~ ENVIRONMENT ~ '/' ~ engine ~ '-' ~ dbpurpose ~ '-master-password' %}
{% set master_pass = salt.vault.read(vault_master_pass_path ) %}
{% if not master_pass %}
{% set master_pass = salt.random.get_str(pw_length) %}
set_{{ name }}_master_password_in_vault:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: vault.write
    - arg:
        - {{ vault_master_pass_path }}
    - kwarg:
        value: {{ master_pass  }}
{% else %}
{% set master_pass = master_pass.data.value %}
{% endif %}

{# If engine is postgres and version is 10, then use major version only for
   parameter group family. All others use major.minor. #}
{% if engine == 'postgres' and int(engine_version.partition('.')[0]) > 9 %}
{% set fam_version = engine_version.partition('.')[0] %}
{% else %}
{% set fam_version = engine_version.rpartition('.')[0] %}
{% endif %}
{% set db_parameter_group_family = engine ~ fam_version | replace('.', '-') %}
{% set db_parameter_group_name = ENVIRONMENT ~ '-' ~ engine ~ '-' ~ db_parameter_group_family ~ '-parameters' %}
{% set default_postgres_parameters = {
    'client_encoding': 'UTF-8',
    'server_encoding': 'UTF-8',
    'log_timezone': 'UTC',
    'timezone': 'UTC',
    'rds.force_ssl': 1
} %}
{% set default_mysql_parameters = {
    'character_set_client': 'utf8',
    'character_set_connection': 'utf8',
    'character_set_database': 'utf8',
    'character_set_filesystem': 'utf8',
    'character_set_results': 'utf8',
    'character_set_server': 'utf8',
    'time_zone': 'UTC'

} %}
{% set default_parameters = {
    'postgres9.6': default_postgres_parameters,
    'postgres10': default_postgres_parameters,
    'mysql5.5': default_mysql_parameters,
    'mysql5.6': default_mysql_parameters,
    'mysql5.7': default_mysql_parameters,
    'mariadb10.2': default_mysql_parameters,
    'mariadb10.3': default_mysql_parameters
} %}

create_{{ ENVIRONMENT }}_{{ name }}_parameter_group:
  boto_rds.parameter_present:
    - name: {{ db_parameter_group_name }}
    - description: Parameters for {{ db_identifier }}
    - db_parameter_group_family: {{ db_parameter_group_family }}
    - parameters: {{ default_parameters[db_parameter_group_family].update(custom_parameters) | json }}

create_{{ ENVIRONMENT }}_{{ name }}_rds_store:
  boto_rds.present:
    - name: {{ db_identifier }}
    - allocated_storage: {{ dbconfig.pop('allocated_storage') }}
    - auto_minor_version_upgrade: True
    - copy_tags_to_snapshot: True
    - db_instance_class: {{ dbconfig.pop('db_instance_class') }}
    - db_name: {{ name }}
    - db_parameter_group_name: {{ db_parameter_group_name }}
    - db_subnet_group_name: db-subnet-group-{{ ENVIRONMENT }}
    - engine: {{ engine }}
    - master_user_password: {{ master_pass }}
    - master_username: {{ master_user }}
    - multi_az: {{ dbconfig.pop('multi_az', True) }}
    - publicly_accessible: {{ public_access }}
    - storage_type: gp2
    - engine_version: {{ engine_version }}
    {% for attr, value in dbconfig.items() %}
    - {{ attr }}: {{ value }}
    {% endfor %}
    - vpc_security_group_ids:
        {% if public_access %}
        - {{ salt.boto_secgroup.get_group_id(
             '{}-rds-public-{}'.format(engine, ENVIRONMENT), vpc_name=VPC_NAME) }}
        {% else %}
        - {{ salt.boto_secgroup.get_group_id(
             '{}-rds-{}'.format(engine, ENVIRONMENT), vpc_name=VPC_NAME) }}
        {% endif %}
        - {{ salt.boto_secgroup.get_group_id(
             'vault-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
    - tags:
        Name: {{ db_identifier }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}
        Purpose: {{ dbpurpose }}
    - require:
        - boto_rds: create_{{ ENVIRONMENT }}_rds_db_subnet_group

{% if replica %}
{% set replica_name = db_identifier ~ '-replica ' %}
create_{{ ENVIRONMENT }}_{{ name }}_rds_replica:
  boto_rds.replica_present:
    - name: {{ replica_name }}
    - source: {{ db_identifier }}
    - db_instance_class: {{ replica.db_instance_class }}
    - publicly_accessible: False
    - tags:
        Name: {{ replica_name }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}
        Purpose: {{ dbpurpose }}
{% endif %}

configure_vault_{{ engine }}_{{ name }}_backend:
  vault.secret_backend_enabled:
    - backend_type: database
    - description: Backend to create dynamic {{ engine }} credentials for {{ ENVIRONMENT }}
    - mount_point: {{ mount_point }}
    - ttl_max: {{ SIX_MONTHS }}
    - ttl_default: {{ SIX_MONTHS }}
    - lease_max: {{ SIX_MONTHS }}
    - lease_default: {{ SIX_MONTHS }}
    - connection_config_path: {{ mount_point }}/config/{{ name }}
    - connection_config:
        plugin_name: {{ vault_plugin }}
        {% if engine == 'postgres' %}
        connection_url: "postgresql://{{ master_user }}:{{ master_pass }}@{{ service_name }}.service.{{ ENVIRONMENT }}.consul:5432/{{ name }}"
        {% else %}
        connection_url: "{{ master_user }}:{{ master_pass }}@tcp({{ service_name }}.service.{{ ENVIRONMENT }}.consul:3306)/"
        {% endif %}
        verify_connection: False
        allowed_roles: '*'
{% endfor %}
