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

create_{{ ENVIRONMENT }}_vpc:
  boto_vpc.present:
    - name: {{ VPC_NAME }}
    - cidr_block: {{ VPC_CIDR }}
    - instance_tenancy: default
    - dns_support: True
    - dns_hostnames: True
    - tags:
        Name: {{ VPC_NAME }}
        business_unit: {{ BUSINESS_UNIT }}

create_{{ ENVIRONMENT }}_internet_gateway:
  boto_vpc.internet_gateway_present:
    - name: {{ ENVIRONMENT }}-igw
    - vpc_name: {{ VPC_NAME }}
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
    - tags:
        Name: {{ VPC_RESOURCE_SUFFIX }}-igw
        business_unit: {{ BUSINESS_UNIT }}

create_{{ ENVIRONMENT }}_public_subnet_1:
  boto_vpc.subnet_present:
    - name: public1-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: {{ cidr_block_public_subnet_1 }}
    - availability_zone: us-east-1b
    - require:
        - boto_vpc: create_{{ VPC_RESOURCE_SUFFIX }}_vpc
    - tags:
        Name: public1-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}

create_{{ ENVIRONMENT }}_public_subnet_2:
  boto_vpc.subnet_present:
    - name: public2-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: {{ cidr_block_public_subnet_2 }}
    - availability_zone: us-east-1c
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
    - tags:
        Name: public2-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}

create_{{ ENVIRONMENT }}_public_subnet_3:
  boto_vpc.subnet_present:
    - name: public3-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: {{ cidr_block_public_subnet_3 }}
    - availability_zone: us-east-1d
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
    - tags:
        Name: public3-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}

create_{{ ENVIRONMENT }}_vpc_peering_connection_with_operations:
  boto_vpc.vpc_peering_connection_present:
    - conn_name: {{ VPC_RESOURCE_SUFFIX }}-operations-peer
    - requester_vpc_name: {{ VPC_NAME }}
    - peer_vpc_name: mitodl-operations-services

accept_{{ VPC_RESOURCE_SUFFIX }}_vpc_peering_connection_with_operations:
  boto_vpc.accept_vpc_peering_connection:
    - conn_name: {{ VPC_RESOURCE_SUFFIX }}-operations-peer

create_{{ ENVIRONMENT }}_routing_table:
  boto_vpc.route_table_present:
    - name: {{ VPC_RESOURCE_SUFFIX }}-route_table
    - vpc_name: {{ VPC_NAME }}
    - subnet_names:
        - public1-{{ VPC_RESOURCE_SUFFIX }}
        - public2-{{ VPC_RESOURCE_SUFFIX }}
        - public3-{{ VPC_RESOURCE_SUFFIX }}
    - routes:
        - destination_cidr_block: 0.0.0.0/0
          internet_gateway_name: {{ VPC_RESOURCE_SUFFIX }}-igw
        - destination_cidr_block: 10.0.0.0/16
          vpc_peering_connection_name: {{ VPC_RESOURCE_SUFFIX }}-operations-peer
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
        - boto_vpc: create_{{ ENVIRONMENT }}_public_subnet_1
        - boto_vpc: create_{{ ENVIRONMENT }}_public_subnet_2
        - boto_vpc: create_{{ ENVIRONMENT }}_public_subnet_3
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc_peering_connection_with_operations
    - tags:
        Name: {{ VPC_RESOURCE_SUFFIX }}-route_table
        business_unit: {{ BUSINESS_UNIT }}

create_salt_master_security_group:
  boto_secgroup.present:
    - name: salt_master-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL to allow Salt master to SSH to instances
    - rules:
        - ip_protocol: tcp
          from_port: 22
          to_port: 22
          cidr_ip: 10.0.0.0/16
    - require:
        - boto_vpc: create_{{ VPC_RESOURCE_SUFFIX }}_vpc
    - tags:
        Name: salt-master-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}
