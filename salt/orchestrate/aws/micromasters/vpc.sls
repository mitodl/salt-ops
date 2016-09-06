{% set VPC_NAME = 'micromasters' %}
{% set VPC_RESOURCE_SUFFIX = VPC_NAME.lower() | replace(' ', '-') %}
{% set VPC_NET_PREFIX = '10.10' %}
{% set ENVIRONMENT = 'micromasters' %}

create_{{ ENVIRONMENT }}_vpc:
  boto_vpc.present:
    - name: {{ VPC_NAME }}
    - cidr_block: {{ VPC_NET_PREFIX }}.0.0/16
    - instance_tenancy: default
    - dns_support: True
    - dns_hostnames: True
    - tags:
        Name: {{ VPC_NAME }}

create_{{ ENVIRONMENT }}_internet_gateway:
  boto_vpc.internet_gateway_present:
    - name: {{ ENVIRONMENT }}-igw
    - vpc_name: {{ VPC_NAME }}
    - require:
        - boto_vpc: create_{{ VPC_NAME.lower() | replace(' ', '-') }}_vpc
    - tags:
        Name: {{ VPC_RESOURCE_SUFFIX }}-igw

create_{{ ENVIRONMENT }}_public_subnet_1:
  boto_vpc.subnet_present:
    - name: public1-{{ VPC_NAME.lower() | replace(' ', '-') }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: {{ VPC_NET_PREFIX }}.1.0/24
    - availability_zone: us-east-1d
    - require:
        - boto_vpc: create_{{ VPC_RESOURCE_SUFFIX }}_vpc
    - tags:
        Name: public1-{{ ENVIRONMENT }}

create_{{ ENVIRONMENT }}_public_subnet_2:
  boto_vpc.subnet_present:
    - name: public2-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: {{ VPC_NET_PREFIX }}.2.0/24
    - availability_zone: us-east-1b
    - require:
        - boto_vpc: create_{{ VPC_NAME }}_vpc
    - tags:
        Name: public2-{{ VPC_RESOURCE_SUFFIX }}

create_{{ ENVIRONMENT }}_public_subnet_3:
  boto_vpc.subnet_present:
    - name: public3-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: {{ VPC_NET_PREFIX }}.3.0/24
    - availability_zone: us-east-1c
    - require:
        - boto_vpc: create_{{ VPC_NAME }}_vpc
    - tags:
        Name: public3-{{ VPC_RESOURCE_SUFFIX }}

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
    - require:
        - boto_vpc: create_{{ VPC_NAME }}_vpc
        - boto_vpc: create_{{ VPC_NAME }}_public_subnet_1
        - boto_vpc: create_{{ VPC_NAME }}_public_subnet_2
        - boto_vpc: create_{{ VPC_NAME }}_public_subnet_3
    - tags:
        Name: {{ VPC_RESOURCE_SUFFIX }}-route_table

create_elasticsearch_security_group:
  boto_secgroup.present:
    - name: elasticsearch-{{ VPC_RESOURCE_SUFFIX }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for elasticsearch servers
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
          from_port: 9300
          to_port: 9400
          source_group_name: elasticsearch-{{ VPC_RESOURCE_SUFFIX }}
    - require:
        - boto_vpc: create_{{ VPC_RESOURCE_SUFFIX }}_vpc
    - tags:
        Name: elasticsearch-{{ VPC_RESOURCE_SUFFIX }}
