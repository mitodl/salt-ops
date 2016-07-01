# Make sure that instance profiles exist for node types so that
# they can be granted access via permissions attached to those
# profiles because it's easier than managing IAM keys
{% for profile in ['consul', 'mongodb', 'rabbitmq', 'edx'] %}
ensure_instance_profile_exists_for_{{ profile }}:
  boto_iam_role.present:
    - name: {{ profile }}-instance-role
{% endfor %}

{% set VPC_NAME = 'Dogwood QA' %}

create_dogwood_qa_vpc:
  boto_vpc.present:
    - name: {{ VPC_NAME }}
    - cidr_block: 10.5.0.0/16
    - instance_tenancy: default
    - dns_support: True
    - dns_hostnames: True
    - tags:
        Name: {{ VPC_NAME }}

create_dogwood_qa_internet_gateway:
  boto_vpc.internet_gateway_present:
    - name: dogwood_qa-igw
    - vpc_name: {{ VPC_NAME }}
    - require:
        - boto_vpc: create_dogwood_qa_vpc
    - tags:
        Name: dogwood_qa-igw

create_dogwood_qa_public_subnet_1:
  boto_vpc.subnet_present:
    - name: public1-dogwood_qa
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.5.1.0/24
    - availability_zone: us-east-1d
    - require:
        - boto_vpc: create_dogwood_qa_vpc
    - tags:
        Name: public1-dogwood_qa

create_dogwood_qa_public_subnet_2:
  boto_vpc.subnet_present:
    - name: public2-dogwood_qa
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.5.2.0/24
    - availability_zone: us-east-1b
    - require:
        - boto_vpc: create_dogwood_qa_vpc
    - tags:
        Name: public2-dogwood_qa

create_dogwood_qa_public_subnet_3:
  boto_vpc.subnet_present:
    - name: public3-dogwood_qa
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.5.3.0/24
    - availability_zone: us-east-1c
    - require:
        - boto_vpc: create_dogwood_qa_vpc
    - tags:
        Name: public3-dogwood_qa

create_dogwood_private_db_subnet:
  boto_vpc.subnet_present:
    - name: private_db_subnet-dogwood_qa
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.5.5.0/24
    - require:
        - boto_vpc: create_dogwood_qa_vpc
    - tags:
        Name: private_db_subnet-dogwood_qa

create_dogwood_qa_routing_table:
  boto_vpc.route_table_present:
    - name: dogwood_qa-route_table
    - vpc_name: {{ VPC_NAME }}
    - subnet_names:
        - public1-dogwood_qa
        - public2-dogwood_qa
        - public3-dogwood_qa
        - private_db_subnet-dogwood_qa
    - routes:
        - destination_cidr_block: 0.0.0.0/0
          internet_gateway_name: dogwood_qa-igw
    - require:
        - boto_vpc: create_dogwood_qa_vpc
        - boto_vpc: create_dogwood_qa_public_subnet_1
        - boto_vpc: create_dogwood_qa_public_subnet_2
        - boto_vpc: create_dogwood_qa_public_subnet_3
    - tags:
        Name: dogwood_qa-route_table

create_edx_security_group:
  boto_secgroup.present:
    - name: edx-dogwood_qa
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
            - 10.0.0.0/16
            - 10.5.0.0/16
    - require:
        - boto_vpc: create_dogwood_qa_vpc
    - tags:
        Name: edx-dogwood_qa

create_mongodb_security_group:
  boto_secgroup.present:
    - name: mongodb-dogwood_qa
    - description: Grant access to Mongo from EdX instances
    - vpc_name: {{ VPC_NAME }}
    - rules:
        - ip_protocol: tcp
          from_port: 27017
          to_port: 27017
          source_group_name: edx-dogwood_qa
        - ip_protocol: tcp
          from_port: 22
          to_port: 22
          cidr_ip:
            - 10.0.0.0/16
            - 10.5.0.0/16
    - require:
        - boto_vpc: create_dogwood_qa_vpc
        - boto_secgroup: create_edx_security_group
    - tags:
        Name: mongodb-dogwood_qa

create_dogwood_consul_security_group:
  boto_secgroup.present:
    - name: consul-dogwood_qa
    - description: Access rules for Consul cluster in {{ VPC_NAME }} stack
    - vpc_name: {{ VPC_NAME }}
    - rules:
        - ip_protocol: tcp
          from_port: 8500
          to_port: 8500
          cidr_ip:
            - 10.5.0.0/16
          {# HTTP access #}
        - ip_protocol: udp
          from_port: 8500
          to_port: 8500
          cidr_ip:
            - 10.5.0.0/16
          {# HTTP access #}
        - ip_protocol: tcp
          from_port: 8600
          to_port: 8600
          cidr_ip:
            - 10.5.0.0/16
          {# DNS access #}
        - ip_protocol: udp
          from_port: 8600
          to_port: 8600
          cidr_ip:
            - 10.5.0.0/16
          {# DNS access #}
        - ip_protocol: tcp
          from_port: 8300
          to_port: 8301
          cidr_ip:
            - 10.5.0.0/16
          {# LAN gossip protocol #}
        - ip_protocol: udp
          from_port: 8301
          to_port: 8301
          cidr_ip:
            - 10.5.0.0/16
          {# LAN gossip protocol #}
        - ip_protocol: tcp
          from_port: 8302
          to_port: 8302
          cidr_ip:
            - 10.0.0.0/16
            - 10.5.0.0/16
          {# WAN cluster interface #}
    - require:
        - boto_vpc: create_dogwood_qa_vpc
    - tags:
        Name: consul-dogwood_qa

create_rabbitmq_security_group:
  boto_secgroup.present:
    - name: rabbitmq-dogwood_qa
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for RabbitMQ servers
    - rules:
        - ip_protocol: tcp
          from_port: 5672
          to_port: 5672
          source_group_name: edx-dogwood_qa
    - require:
        - boto_vpc: create_dogwood_qa_vpc
        - boto_secgroup: create_edx_security_group
    - tags:
        Name: rabbitmq-dogwood_qa

create_rds_security_group:
  boto_secgroup.present:
    - name: rds-dogwood_qa
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for RDS access
    - rules:
        - ip_protocol: tcp
          from_port: 3306
          to_port: 3306
          source_group_name: edx-dogwood_qa
    - require:
        - boto_vpc: create_dogwood_qa_vpc
        - boto_secgroup: create_edx_security_group
    - tags:
        Name: rds-dogwood_qa

create_salt_master_security_group:
  boto_secgroup.present:
    - name: salt_master-dogwood_qa
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for allowing access to hosts from Salt Master
    - tags:
        Name: salt_master-dogwood_qa
    - rules:
        - ip_protocol: tcp
          from_port: 22
          to_port: 22
          cidr_ip:
            - 10.0.0.0/16
    - require:
        - boto_vpc: create_dogwood_qa_vpc
