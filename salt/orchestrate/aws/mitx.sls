#!jinja|yaml

# Make sure that instance profiles exist for node types so that
# they can be granted access via permissions attached to those
# profiles because it's easier than managing IAM keys
{% set env_data = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'mitx-qa') %}
{% set env_settings = env_data.environments[ENVIRONMENT] %}
{% set PURPOSE_PREFIX = salt.environ.get('PURPOSE_PREFIX', 'current-residential') %}
{% set VPC_NAME = env_settings.vpc_name %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_settings.business_unit) %}

{% set network_prefix = env_settings.network_prefix %}
{% set cidr_block_public_subnet_1 = '{}.1.0/24'.format(network_prefix) %}
{% set cidr_block_public_subnet_2 = '{}.2.0/24'.format(network_prefix) %}
{% set cidr_block_public_subnet_3 = '{}.3.0/24'.format(network_prefix) %}
{% set cidr_ip = '{}.0.0/22'.format(network_prefix) %}
{% set cidr_block = '{}.0.0/16'.format(network_prefix) %}

create_{{ ENVIRONMENT }}_vpc:
  boto_vpc.present:
    - name: {{ VPC_NAME }}
    - cidr_block: {{ cidr_block }}
    - instance_tenancy: default
    - dns_support: True
    - dns_hostnames: True
    - tags:
        Name: {{ VPC_NAME }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_{{ ENVIRONMENT }}_internet_gateway:
  boto_vpc.internet_gateway_present:
    - name: {{ ENVIRONMENT }}-igw
    - vpc_name: {{ VPC_NAME }}
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
    - tags:
        Name: {{ ENVIRONMENT }}-igw
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_{{ ENVIRONMENT }}_public_subnet_1:
  boto_vpc.subnet_present:
    - name: public1-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: {{ cidr_block_public_subnet_1 }}
    - availability_zone: us-east-1d
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
    - tags:
        Name: public1-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_{{ ENVIRONMENT }}_public_subnet_2:
  boto_vpc.subnet_present:
    - name: public2-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: {{ cidr_block_public_subnet_2 }}
    - availability_zone: us-east-1b
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
    - tags:
        Name: public2-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_{{ ENVIRONMENT }}_public_subnet_3:
  boto_vpc.subnet_present:
    - name: public3-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: {{ cidr_block_public_subnet_3 }}
    - availability_zone: us-east-1c
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
    - tags:
        Name: public3-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_{{ ENVIRONMENT }}_vpc_peering_connection_with_operations:
  boto_vpc.vpc_peering_connection_present:
    - conn_name: {{ ENVIRONMENT }}-operations-peer
    - requester_vpc_name: {{ VPC_NAME }}
    - peer_vpc_name: mitodl-operations-services

accept_{{ ENVIRONMENT }}_vpc_peering_connection_with_operations:
  boto_vpc.accept_vpc_peering_connection:
    - conn_name: {{ ENVIRONMENT }}-operations-peer

create_{{ ENVIRONMENT }}_routing_table:
  boto_vpc.route_table_present:
    - name: {{ ENVIRONMENT }}-route_table
    - vpc_name: {{ VPC_NAME }}
    - subnet_names:
        - public1-{{ ENVIRONMENT }}
        - public2-{{ ENVIRONMENT }}
        - public3-{{ ENVIRONMENT }}
    - routes:
        - destination_cidr_block: 0.0.0.0/0
          internet_gateway_name: {{ ENVIRONMENT }}-igw
        - destination_cidr_block: 10.0.0.0/22
          vpc_peering_connection_name: {{ ENVIRONMENT }}-operations-peer
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
        - boto_vpc: create_{{ ENVIRONMENT }}_public_subnet_1
        - boto_vpc: create_{{ ENVIRONMENT }}_public_subnet_2
        - boto_vpc: create_{{ ENVIRONMENT }}_public_subnet_3
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc_peering_connection_with_operations
    - tags:
        Name: {{ ENVIRONMENT }}-route_table
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_edx_security_group:
  boto_secgroup.present:
    - name: edx-{{ ENVIRONMENT }}
    - description: Access rules for EdX instances
    - vpc_name: {{ VPC_NAME }}
    - rules:
        - ip_protocol: tcp
          from_port: 80
          to_port: 80
          cidr_ip: 0.0.0.0/0
        - ip_protocol: tcp
          from_port: 443
          to_port: 443
          cidr_ip: 0.0.0.0/0
        - ip_protocol: tcp
          from_port: 22
          to_port: 22
          cidr_ip:
            - 10.0.0.0/22
            - {{ cidr_ip }}
        - ip_protocol: tcp
          from_port: 18040
          to_port: 18040
          cidr_ip: {{ cidr_ip }}
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
    - tags:
        Name: edx-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_edx_worker_security_group:
  boto_secgroup.present:
    - name: edx-worker-{{ ENVIRONMENT }}
    - description: Grant access to edx-worker from EdX instances
    - vpc_name: {{ VPC_NAME }}
    - rules:
        - ip_protocol: tcp
          from_port: 18040
          to_port: 18040
          source_group_name:
            - edx-{{ ENVIRONMENT }}
            - edx-worker-{{ ENVIRONMENT }}
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
        - boto_secgroup: create_edx_security_group
    - tags:
        Name: edx-worker-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_mongodb_security_group:
  boto_secgroup.present:
    - name: mongodb-{{ ENVIRONMENT }}
    - description: Grant access to Mongo from EdX instances
    - vpc_name: {{ VPC_NAME }}
    - rules:
        - ip_protocol: tcp
          from_port: 27017
          to_port: 27017
          source_group_name:
            - edx-{{ ENVIRONMENT }}
            - edx-worker-{{ ENVIRONMENT }}
            - mongodb-{{ ENVIRONMENT }}
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
        - boto_secgroup: create_edx_security_group
    - tags:
        Name: mongodb-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_mitx_consul_security_group:
  boto_secgroup.present:
    - name: consul-{{ ENVIRONMENT }}
    - description: Access rules for Consul cluster in {{ VPC_NAME }} stack
    - vpc_name: {{ VPC_NAME }}
    - rules:
        - ip_protocol: tcp
          from_port: 8500
          to_port: 8500
          cidr_ip:
            - {{ cidr_ip }}
          {# HTTP access #}
        - ip_protocol: udp
          from_port: 8500
          to_port: 8500
          cidr_ip:
            - {{ cidr_ip }}
          {# HTTP access #}
        - ip_protocol: tcp
          from_port: 8600
          to_port: 8600
          cidr_ip:
            - {{ cidr_ip }}
          {# DNS access #}
        - ip_protocol: udp
          from_port: 8600
          to_port: 8600
          cidr_ip:
            - {{ cidr_ip }}
          {# DNS access #}
        - ip_protocol: tcp
          from_port: 8300
          to_port: 8301
          cidr_ip:
            - {{ cidr_ip }}
          {# LAN gossip protocol #}
        - ip_protocol: udp
          from_port: 8300
          to_port: 8301
          cidr_ip:
            - {{ cidr_ip }}
          {# LAN gossip protocol #}
        - ip_protocol: tcp
          from_port: 8300
          to_port: 8302
          cidr_ip:
            - 10.0.0.0/22
            - {{ cidr_ip }}
          {# WAN cluster interface #}
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
    - tags:
        Name: consul-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_mitx_consul_agent_security_group:
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
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
        - boto_secgroup: create_mitx_consul_security_group
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
          source_group_name: edx-{{ ENVIRONMENT }}
        - ip_protocol: tcp
          from_port: 5672
          to_port: 5672
          source_group_name: edx-worker-{{ ENVIRONMENT }}
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
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
        - boto_secgroup: create_edx_security_group
    - tags:
        Name: rabbitmq-{{ ENVIRONMENT }}
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
          source_group_name: edx-{{ ENVIRONMENT }}
        - ip_protocol: tcp
          from_port: 9200
          to_port: 9200
          source_group_name: edx-worker-{{ ENVIRONMENT }}
        - ip_protocol: tcp
          from_port: 9300
          to_port: 9400
          source_group_name: elasticsearch-{{ ENVIRONMENT }}
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
        - boto_secgroup: create_edx_security_group
    - tags:
        Name: elasticsearch-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_mysql_rds_security_group:
  boto_secgroup.present:
    - name: mariadb-rds-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for RDS access
    - rules:
        - ip_protocol: tcp
          from_port: 3306
          to_port: 3306
          source_group_name: edx-{{ ENVIRONMENT }}
        - ip_protocol: tcp
          from_port: 3306
          to_port: 3306
          source_group_name: edx-worker-{{ ENVIRONMENT }}
        - ip_protocol: tcp
          from_port: 3306
          to_port: 3306
          source_group_name: consul-{{ ENVIRONMENT }}
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
        - boto_secgroup: create_edx_security_group
    - tags:
        Name: mariadb-rds-{{ ENVIRONMENT }}
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
            - {{ cidr_ip }}
    - tags:
        Name: postgres-rds-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_master_ssh_security_group:
  boto_secgroup.present:
    - name: master-ssh-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for allowing access to hosts from Salt Master
    - tags:
        Name: master-ssh-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}
    - rules:
        - ip_protocol: tcp
          from_port: 22
          to_port: 22
          cidr_ip:
            - 10.0.0.0/22
        # netdata:
        - ip_protocol: tcp
          from_port: 19999
          to_port: 19999
          cidr_ip:
            - 10.0.0.0/22
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc

create_public_ssh_security_group:
  boto_secgroup.present:
    - name: public-ssh-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for allowing access to hosts from the open internet
    - tags:
        Name: publich-ssh-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}
    - rules:
        - ip_protocol: tcp
          from_port: 22
          to_port: 22
          cidr_ip:
            - 0.0.0.0/0
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc

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
        {# MongoDB #}
        - ip_protocol: tcp
          from_port: 27017
          to_port: 27017
          cidr_ip:
            - 10.0.0.0/22
        {# RabbitMQ #}
        - ip_protocol: tcp
          from_port: 15672
          to_port: 15672
          cidr_ip:
            - 10.0.0.0/22
        {# MySQL #}
        - ip_protocol: tcp
          from_port: 3306
          to_port: 3306
          cidr_ip:
            - 10.0.0.0/22
        {# PostGreSQL #}
        - ip_protocol: tcp
          from_port: 5432
          to_port: 5432
          cidr_ip:
            - 10.0.0.0/22
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
