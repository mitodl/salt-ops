{% from "orchestrate/aws_env_macro.jinja" import VPC_NAME, VPC_RESOURCE_SUFFIX,
 ENVIRONMENT, BUSINESS_UNIT, subnet_ids with context %}

{% set SIX_MONTHS = '4368h' %}
{% set master_pass = salt.random.get_str(40) %}
{% set master_user = salt.pillar.get('rds:master_username', 'odldevops') %}

create_edx_rds_db_subnet_group:
  boto_rds.subnet_group_present:
    - name: db-subnet-group-{{VPC_RESOURCE_SUFFIX }}
    - description: Subnet group for MySQL instance in {{ ENVIRONMENT }}
    - subnet_ids: {{ subnet_ids }}
    - tags:
        Name: db-subnet-group-{{VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}

create_edx_rds_store:
  boto_rds.present:
    - name: {{ ENVIRONMENT }}-rds-mysql
    - allocated_storage: 200
    - db_instance_class: db.t2.medium
    - storage_type: gp2
    - engine: mariadb
    - multi_az: True
    - auto_minor_version_upgrade: True
    - publicly_accessible: False
    - master_username: {{ master_user }}
    - master_user_password: {{ master_pass }}
    - vpc_security_group_ids:
        - {{ salt.boto_secgroup.get_group_id(
             'edx-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        - {{ salt.boto_secgroup.get_group_id(
             'default', vpc_name=VPC_NAME) }}
        - {{ salt.boto_secgroup.get_group_id(
             'vault-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
    - db_subnet_group_name: db-subnet-group-{{ VPC_RESOURCE_SUFFIX }}
    - copy_tags_to_snapshot: True
    - tags:
        Name: {{ VPC_RESOURCE_SUFFIX }}-rds-mysql
        business_unit: {{ BUSINESS_UNIT }}
    - require:
        - boto_rds: create_edx_rds_db_subnet_group

configure_vault_mysql_backend:
  vault.secret_backend_enabled:
    - backend_type: mysql
    - description: Backend to create dynamic MySQL credentials for {{ ENVIRONMENT }}
    - mount_point: mysql-{{ ENVIRONMENT }}
    - ttl_max: {{ SIX_MONTHS }}
    - ttl_default: {{ SIX_MONTHS }}
    - lease_max: {{ SIX_MONTHS }}
    - lease_default: {{ SIX_MONTHS }}
    - connection_config:
        connection_url: "{{ master_user }}:{{ master_pass }}@tcp(mysql.service.{{ ENVIRONMENT }}.consul:3306)/"
        verify: False
    - require:
        - boto_rds: create_edx_rds_store
