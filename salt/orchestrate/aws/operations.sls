{% set VPC_NAME='mitodl-operations-services' %}
{% set VPC_RESOURCE_SUFFIX = 'operations' %}
{% set ENVIRONMENT = 'operations') %}
{% set BUSINESS_UNIT = 'operations' %}

create_operations_public_subnet_1:
  boto_vpc.subnet_present:
    - name: public1-operations
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.0.1.0/24
    - availability_zone: us-east-1d
    - tags:
        Name: public1-operations
        business_unit: {{ BUSINESS_UNIT }}

create_operations_public_subnet_2:
  boto_vpc.subnet_present:
    - name: public2-operations
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.0.2.0/24
    - availability_zone: us-east-1b
    - tags:
        Name: public2-operations
        business_unit: {{ BUSINESS_UNIT }}

create_operations_public_subnet_3:
  boto_vpc.subnet_present:
    - name: public3-operations
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.0.3.0/24
    - availability_zone: us-east-1c
    - tags:
        Name: public3-operations
        business_unit: {{ BUSINESS_UNIT }}

manage_operations_routing_table:
  boto_vpc.route_table_present:
    - name: operations-route_table
    - vpc_name: {{ VPC_NAME }}
    - subnet_names:
        - public1-operations
        - public2-operations
        - public3-operations
    - routes:
        - destination_cidr_block: 0.0.0.0/0
          internet_gateway_name: operations-igw
    - tags:
        Name: operations-route_table
        business_unit: {{ BUSINESS_UNIT }}

create_operations_consul_security_group:
  boto_secgroup.present:
    - name: consul-operations
    - description: Access rules for Consul cluster in operations VPC
    - vpc_name: mitodl-operations-services
    - rules:
        - ip_protocol: tcp
          from_port: 8500
          to_port: 8500
          source_group_name: default
          {# HTTP access #}
        - ip_protocol: udp
          from_port: 8500
          to_port: 8500
          source_group_name: default
          {# HTTP access #}
        - ip_protocol: tcp
          from_port: 8600
          to_port: 8600
          source_group_name: default
          {# DNS access #}
        - ip_protocol: udp
          from_port: 8600
          to_port: 8600
          source_group_name: default
          {# DNS access #}
        - ip_protocol: tcp
          from_port: 8301
          to_port: 8301
          source_group_name: default
          {# LAN gossip protocol #}
        - ip_protocol: udp
          from_port: 8301
          to_port: 8301
          source_group_name: default
          {# LAN gossip protocol #}
        - ip_protocol: tcp
          from_port: 8302
          to_port: 8302
          cidr_ip:
            - 10.0.0.0/16
            - 10.5.0.0/16
            - 10.6.0.0/16
            - 10.7.0.0/16
          {# WAN cluster interface #}

create_mitx_consul_agent_security_group:
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
        - boto_vpc: create_{{ VPC_RESOURCE_SUFFIX_UNDERSCORE }}_vpc
        - boto_secgroup: create_mitx_consul_security_group
    - tags:
        Name: consul-agent-{{ VPC_RESOURCE_SUFFIX }}
        business_unit: {{ BUSINESS_UNIT }}

create_vault_security_group:
  boto_secgroup.present:
    - name: vault-operations
    - description: ACL for vault in operations VPC
    - vpc_name: mitodl-operations-services
    - rules:
        - ip_protocol: tcp
          from_port: 8200
          to_port: 8200
          source_group_name: default
    - tags:
        Name: vault-operations
        business_unit: {{ BUSINESS_UNIT }}
