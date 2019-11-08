{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set env_data = salt.pillar.get('environments') %}
{% set env_settings = env_data[ENVIRONMENT] %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', env_settings.vpc_name) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_settings.business_unit) %}
{% set vpc_peers = env_settings.get('vpc_peers', []) %}

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
    - availability_zone: us-east-1b
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
    - availability_zone: us-east-1c
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
    - availability_zone: us-east-1d
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
    - tags:
        Name: public3-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

{% for peer in vpc_peers %}
create_{{ ENVIRONMENT }}_vpc_peering_connection_with_{{ peer }}:
  boto_vpc.vpc_peering_connection_present:
    - conn_name: {{ ENVIRONMENT }}-{{ peer }}-peer
    - requester_vpc_name: {{ VPC_NAME }}
    - peer_vpc_name: {{ peer }}
    - require_in:
        - boto_vpc: create_{{ ENVIRONMENT }}_routing_table

accept_{{ ENVIRONMENT }}_vpc_peering_connection_with_{{ peer }}:
  boto_vpc.accept_vpc_peering_connection:
    - conn_name: {{ ENVIRONMENT }}-{{ peer }}-peer
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc_peering_connection_with_{{ peer }}
{% endfor %}

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
        {% for peer in vpc_peers %}
        - destination_cidr_block: {{ env_data[peer].network_prefix }}.0.0/16
          vpc_peering_connection_name: {{ ENVIRONMENT }}-{{ peer }}-peer
        {% endfor %}
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
        - boto_vpc: create_{{ ENVIRONMENT }}_public_subnet_1
        - boto_vpc: create_{{ ENVIRONMENT }}_public_subnet_2
        - boto_vpc: create_{{ ENVIRONMENT }}_public_subnet_3
    - tags:
        Name: {{ ENVIRONMENT }}-route_table
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}
