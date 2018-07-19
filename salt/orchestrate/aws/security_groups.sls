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
{% set ODL_WIRED_CIDR = '18.124.0.0/16' %}
{% set ODL_WIRELESS_CIDR = '18.40.64.0/19' %}
{% set MIT_VPN_0_CIDR = '18.100.0.0/16' %}
{% set MIT_VPN_1_CIDR = '18.101.0.0/16' %}

create_salt_master_security_group:
  boto_secgroup.present:
    - name: salt_master-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL to allow Salt master to SSH to instances
    - rules:
        - ip_protocol: tcp
          from_port: 22
          to_port: 22
          cidr_ip: 10.0.0.0/16
    - tags:
        Name: salt-master-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_vault_backend_security_group:
  boto_secgroup.present:
    - name: vault-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: >-
        ACL to allow Vault to access data stores so that it
        can create dynamic credentials
    - tags:
        Name: vault-{{ ENVIRONMENT }}
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
    - name: consul-{{ ENVIRONMENT }}
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
        Name: consul-{{ ENVIRONMENT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}

create_{{ ENVIRONMENT }}_consul_agent_security_group:
  boto_secgroup.present:
    - name: consul-agent-{{ ENVIRONMENT }}
    - description: Access rules for Consul agent in {{ VPC_NAME }} stack
    - vpc_name: {{ VPC_NAME }}
    - rules:
        - ip_protocol: tcp
          from_port: 8301
          to_port: 8301
          source_group_name: consul-agent-{{ ENVIRONMENT }}
        - ip_protocol: udp
          from_port: 8301
          to_port: 8301
          source_group_name: consul-agent-{{ ENVIRONMENT }}
        - ip_protocol: tcp
          from_port: 8301
          to_port: 8301
          source_group_name: consul-{{ ENVIRONMENT }}
        - ip_protocol: udp
          from_port: 8301
          to_port: 8301
          source_group_name: consul-{{ ENVIRONMENT }}
    - require:
        - boto_secgroup: create_{{ ENVIRONMENT }}_consul_security_group
    - tags:
        Name: consul-agent-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_rabbitmq_security_group:
  boto_secgroup.present:
    - name: rabbitmq-{{ ENVIRONMENT }}
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
          source_group_name: rabbitmq-{{ ENVIRONMENT }}
        - ip_protocol: tcp
          from_port: 25672
          to_port: 25672
          source_group_name: rabbitmq-{{ ENVIRONMENT }}
        - ip_protocol: tcp
          from_port: 35672
          to_port: 35682
          source_group_name: rabbitmq-{{ ENVIRONMENT }}
    - tags:
        Name: rabbitmq-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_postgres_rds_security_group:
  boto_secgroup.present:
    - name: postgres-rds-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for PostGreSQL RDS servers
    - rules:
        - ip_protocol: tcp
          from_port: 5432
          to_port: 5432
          cidr_ip:
            - {{ VPC_CIDR }}
    - tags:
        Name: postgres-rds-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_public_postgres_rds_security_group:
  boto_secgroup.present:
    - name: postgres-rds-public-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: Allow public access to PostGres RDS servers
    - rules:
        - ip_protocol: tcp
          from_port: 5432
          to_port: 5432
          cidr_ip:
            - 0.0.0.0/0
    - tags:
        Name: postgres-rds-public-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_mariadb_rds_security_group:
  boto_secgroup.present:
    - name: mariadb-rds-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for MariaDB RDS servers
    - rules:
        - ip_protocol: tcp
          from_port: 3306
          to_port: 3306
          cidr_ip:
            - {{ VPC_CIDR }}
    - tags:
        Name: mariadb-rds-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_public_mysql_rds_security_group:
  boto_secgroup.present:
    - name: mariadb-rds-public-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: Allow public access to MariaDB RDS servers
    - rules:
        - ip_protocol: tcp
          from_port: 3306
          to_port: 3306
          cidr_ip:
            - 0.0.0.0/0
    - tags:
        Name: mariadb-rds-public-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_scylladb_rds_security_group:
  boto_secgroup.present:
    - name: scylladb-{{ ENVIRONMENT }}
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
        Name: scylladb-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_webapp_security_group:
  boto_secgroup.present:
    - name: webapp-{{ ENVIRONMENT }}
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
        Name: webapp-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_webapp_odl_vpn_security_group:
  boto_secgroup.present:
    - name: webapp-odl-vpn-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for web servers accessible only from ODL and VPN
    - rules:
        - ip_protocol: tcp
          from_port: 443
          to_port: 443
          cidr_ip:
            - {{ ODL_WIRED_CIDR }}
            - {{ ODL_WIRELESS_CIDR }}
            - {{ MIT_VPN_0_CIDR }}
            - {{ MIT_VPN_1_CIDR }}
    - tags:
        Name: webapp-odl-vpn-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_elasticsearch_security_group:
  boto_secgroup.present:
    - name: elasticsearch-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for elasticsearch servers
    - rules:
        - ip_protocol: tcp
          from_port: 9200
          to_port: 9200
          source_group_name: default
        - ip_protocol: tcp
          from_port: 9300
          to_port: 9400
          source_group_name: elasticsearch-{{ ENVIRONMENT }}
    - tags:
        Name: elasticsearch-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
