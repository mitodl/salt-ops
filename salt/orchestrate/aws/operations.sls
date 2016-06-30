{% set VPC_NAME='mitodl=operations-services' %}

create_operations_public_subnet_1:
  boto_vpc.subnet_present:
    - name: public1-operations
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.0.1.0/24
    - availability_zone: us-east-1d
    - tags:
        Name: public1-operations

create_operations_public_subnet_2:
  boto_vpc.subnet_present:
    - name: public2-operations
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.0.2.0/24
    - availability_zone: us-east-1b
    - tags:
        Name: public2-operations

create_operations_public_subnet_3:
  boto_vpc.subnet_present:
    - name: public3-operations
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.0.3.0/24
    - availability_zone: us-east-1c
    - tags:
        Name: public3-operations

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
          {# WAN cluster interface #}

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
