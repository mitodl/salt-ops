{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set env_settings = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', env_settings.vpc_name) %}
{% set VPC_RESOURCE_SUFFIX = salt.environ.get(
    'VPC_RESOURCE_SUFFIX',
    VPC_NAME.lower().replace(' ', '-')) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_settings.business_unit) %}

{% set VPC_CIDR = env_settings.cidr_block %}
{% set purpose_data = env_settings.purposes %}

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
{% set subnet_list = [] %}
{% for purpose, config in purpose_data.items() %}
{% for az, cidr in config.subnets.items() %}
{% set subnet_name = 'subnet-{p}-{a}-{v}'.format(p=purpose, a=az, v=VPC_RESOURCE_SUFFIX) %}
create_{{ ENVIRONMENT }}_{{ purpose }}_{{ az }}_subnet:
  boto_vpc.subnet_present:
    - name: {{ subnet_name }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: {{ cidr }}
    - availability_zone: {{ az }}
    - require:
        - boto_vpc: create_{{ VPC_RESOURCE_SUFFIX }}_vpc
    - tags:
        Name: {{ subnet_name }}
        purpose: {{ purpose }}
    - require_in:
        - boto_vpc: create_{{ ENVIRONMENT }}_routing_table
{% do subnet_list.append(subnet_name) %}
{% endfor %}
{% endfor %}

create_{{ ENVIRONMENT }}_vpc_peering_connection_with_operations:
  boto_vpc.vpc_peering_connection_present:
    - conn_name: {{ VPC_RESOURCE_SUFFIX }}-operations-peer
    - requester_vpc_name: {{ VPC_NAME }}
    - peer_vpc_name: mitodl-operations-services

create_{{ ENVIRONMENT }}_routing_table:
  boto_vpc.route_table_present:
    - name: {{ VPC_RESOURCE_SUFFIX }}-route_table
    - vpc_name: {{ VPC_NAME }}
    - subnet_names: {{ subnet_list }}
    - routes:
        - destination_cidr_block: 0.0.0.0/0
          internet_gateway_name: {{ VPC_RESOURCE_SUFFIX }}-igw
        - destination_cidr_block: 10.0.0.0/16
          vpc_peering_connection_name: {{ VPC_RESOURCE_SUFFIX }}-operations-peer
    - require:
        - boto_vpc: create_{{ VPC_NAME }}_vpc
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
