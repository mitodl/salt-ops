{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set env_settings = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', env_settings.vpc_name) %}
{% set VPC_RESOURCE_SUFFIX = salt.environ.get(
    'VPC_RESOURCE_SUFFIX',
    VPC_NAME.lower().replace(' ', '-')) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_settings.business_unit) %}

{% set network_prefix = env_settings.network_prefix %}
{% set cidr_block_public_subnet_1 = '{}.1.0/24'.format(network_prefix) %}
{% set cidr_block_public_subnet_2 = '{}.2.0/24'.format(network_prefix) %}
{% set cidr_block_public_subnet_3 = '{}.3.0/24'.format(network_prefix) %}
{% set SUBNETS_CIDR = '{}.0.0/22'.format(network_prefix) %}
{% set VPC_CIDR = '{}.0.0/16'.format(network_prefix) %}

create_vault_backend_security_group:
  boto_secgroup.present:
    - name: vault-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - description: >-
        ACL to allow Vault to access data stores so that it
        can create dynamic credentials
    - tags:
        Name: vault-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}
    - rules:
        {# RabbitMQ #}
        - ip_protocol: tcp
          from_port: 15672
          to_port: 15672
          cidr_ip:
            - 10.0.0.0/22
        {# PostGreSQL #}
        - ip_protocol: tcp
          from_port: 5432
          to_port: 5432
          cidr_ip:
            - 10.0.0.0/22

create_{{ ENVIRONMENT }}_consul_security_group:
  boto_secgroup.present:
    - name: consul-{{ VPC_RESOURCE_SUFFIX }}
    - description: Access rules for Consul cluster in {{ VPC_NAME }} stack
    - vpc_name: {{ VPC_NAME }}
    - rules:
        - ip_protocol: tcp
          from_port: 8500
          to_port: 8500
          cidr_ip:
            - {{ VPC_CIDR }}
          {# HTTP access #}
        - ip_protocol: udp
          from_port: 8500
          to_port: 8500
          cidr_ip:
            - {{ VPC_CIDR }}
          {# HTTP access #}
        - ip_protocol: tcp
          from_port: 8600
          to_port: 8600
          cidr_ip:
            - {{ VPC_CIDR }}
          {# DNS access #}
        - ip_protocol: udp
          from_port: 8600
          to_port: 8600
          cidr_ip:
            - {{ VPC_CIDR }}
          {# DNS access #}
        - ip_protocol: tcp
          from_port: 8300
          to_port: 8301
          cidr_ip:
            - {{ VPC_CIDR }}
          {# LAN gossip protocol #}
        - ip_protocol: udp
          from_port: 8300
          to_port: 8301
          cidr_ip:
            - {{ VPC_CIDR }}
          {# LAN gossip protocol #}
        - ip_protocol: tcp
          from_port: 8300
          to_port: 8302
          cidr_ip:
            - 10.0.0.0/22
            - {{ VPC_CIDR }}
          {# WAN cluster interface #}
    - tags:
        Name: consul-{{ VPC_RESOURCE_SUFFIX }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}

create_{{ ENVIRONMENT }}_consul_agent_security_group:
  boto_secgroup.present:
    - name: consul-agent-{{ VPC_RESOURCE_SUFFIX }}
    - description: Access rules for Consul agent in {{ VPC_NAME }} stack
    - vpc_name: {{ VPC_NAME }}
    - rules:
        - ip_protocol: tcp
          from_port: 8301
          to_port: 8301
          source_group_name: consul-agent-{{ VPC_RESOURCE_SUFFIX }}
        - ip_protocol: udp
          from_port: 8301
          to_port: 8301
          source_group_name: consul-agent-{{ VPC_RESOURCE_SUFFIX }}
        - ip_protocol: tcp
          from_port: 8301
          to_port: 8301
          source_group_name: consul-{{ VPC_RESOURCE_SUFFIX }}
        - ip_protocol: udp
          from_port: 8301
          to_port: 8301
          source_group_name: consul-{{ VPC_RESOURCE_SUFFIX }}
    - require:
        - boto_secgroup: create_{{ ENVIRONMENT }}_consul_security_group
    - tags:
        Name: consul-agent-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_rabbitmq_security_group:
  boto_secgroup.present:
    - name: rabbitmq-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for RabbitMQ servers
    - rules:
        - ip_protocol: tcp
          from_port: 5672
          to_port: 5672
          cidr_ip:
            - {{ VPC_CIDR }}
        - ip_protocol: tcp
          from_port: 4369
          to_port: 4369
          source_group_name: rabbitmq-{{ VPC_RESOURCE_SUFFIX }}
        - ip_protocol: tcp
          from_port: 25672
          to_port: 25672
          source_group_name: rabbitmq-{{ VPC_RESOURCE_SUFFIX }}
    - tags:
        Name: rabbitmq-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_postgres_rds_security_group:
  boto_secgroup.present:
    - name: postgres-rds-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for PostGreSQL RDS servers
    - rules:
        - ip_protocol: tcp
          from_port: 5432
          to_port: 5432
          cidr_ip:
            - {{ VPC_CIDR }}
    - tags:
        Name: postgres-rds-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_public_postgres_rds_security_group:
  boto_secgroup.present:
    - name: postgres-rds-public-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - description: Allow public access to PostGres RDS servers
    - rules:
        - ip_protocol: tcp
          from_port: 5432
          to_port: 5432
          cidr_ip:
            - 0.0.0.0/0
    - tags:
        Name: postgres-rds-public-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_mariadb_rds_security_group:
  boto_secgroup.present:
    - name: mariadb-rds-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for MariaDB RDS servers
    - rules:
        - ip_protocol: tcp
          from_port: 3306
          to_port: 3306
          cidr_ip:
            - {{ VPC_CIDR }}
    - tags:
        Name: mariadb-rds-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_public_mysql_rds_security_group:
  boto_secgroup.present:
    - name: mariadb-rds-public-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - description: Allow public access to MariaDB RDS servers
    - rules:
        - ip_protocol: tcp
          from_port: 3306
          to_port: 3306
          cidr_ip:
            - 0.0.0.0/0
    - tags:
        Name: mariadb-rds-public-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_scylladb_rds_security_group:
  boto_secgroup.present:
    - name: scylladb-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for Scylladb servers
    - rules:
        {% for portnum in [7000, 7001, 7199, 9042, 9100, 9160, 9180, 10000] %}
        - ip_protocol: tcp
          from_port: {{ portnum }}
          to_port: {{ portnum }}
          cidr_ip:
            - {{ VPC_CIDR }}
        {% endfor %}
    - tags:
        Name: scylladb-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_webapp_security_group:
  boto_secgroup.present:
    - name: webapp-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for web servers
    - rules:
        - ip_protocol: tcp
          from_port: 80
          to_port: 80
          cidr_ip:
            - 0.0.0.0/0
            - '::/0'
        - ip_protocol: tcp
          from_port: 443
          to_port: 443
          cidr_ip:
            - 0.0.0.0/0
            - '::/0'
    - tags:
        Name: webapp-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_fluentd_aggregator_security_group:
  boto_secgroup.present:
    - name: fluentd-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for Fluentd aggretators
    - rules:
        {% for portnum in [443, 5001] %}
        - ip_protocol: tcp
          from_port: {{ portnum }}
          to_port: {{ portnum }}
          cidr_ip:
            - 0.0.0.0/0
            - '::/0'
        {% endfor %}
    - tags:
        Name: fluentd-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}
