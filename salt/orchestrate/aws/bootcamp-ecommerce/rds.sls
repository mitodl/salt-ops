{% from "orchestrate/aws_env_macro.jinja" import VPC_NAME, VPC_RESOURCE_SUFFIX,
 ENVIRONMENT, subnet_ids with context %}
{% set ISO8601 = '%Y-%m-%dT%H:%M:%S' %}
{% set SIX_MONTHS = '4368h' %}
{% set master_pass = salt.random.get_str(42) %}
{% set master_user = 'odldevops' %}

create_{{ ENVIRONMENT }}_rds_db_subnet_group:
  boto_rds.subnet_group_present:
    - name: db-subnet-group-{{VPC_RESOURCE_SUFFIX }}
    - description: Subnet group for Bootcamp Ecommerce RDS instance
    - subnet_ids: {{ subnet_ids }}
    - tags:
        Name: db-subnet-group-{{VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        created_at: "{{ salt.status.time(format=ISO8601) }}"

create_{{ ENVIRONMENT }}_rds_store:
  boto_rds.present:
    - name: {{ VPC_RESOURCE_SUFFIX }}-rds-postgresql
    - allocated_storage: 50
    - db_instance_class: db.t2.micro
    - db_name: bootcamp_ecommerce
    - storage_type: gp2
    - engine: postgres
    - multi_az: True
    - auto_minor_version_upgrade: True
    - publicly_accessible: True
    - master_username: {{ master_user }}
    - master_user_password: {{ master_pass }}
    - vpc_security_group_ids:
        - {{ salt.boto_secgroup.get_group_id(
             'default', vpc_name=VPC_NAME) }}
        - {{ salt.boto_secgroup.get_group_id(
             'vault-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        - {{ salt.boto_secgroup.get_group_id(
             'postgresql-rds-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
    - db_subnet_group_name: db-subnet-group-{{ VPC_RESOURCE_SUFFIX }}
    - copy_tags_to_snapshot: True
    - tags:
        Name: {{ VPC_RESOURCE_SUFFIX }}-rds-mysql
        business_unit: bootcamps
        created_at: "{{ salt.status.time(format=ISO8601) }}"
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
        connection_url: "postgresql://{{ master_user }}:{{ master_pass }}@bootcamps-db.service.consul:5432/bootcamp_ecommerce"
        verify_connection: False
