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

create_dogwood_qa_public_subnet:
  boto_vpc.subnet_present:
    - name: public-dogwood_qa
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.5.0.0/24

create_dogwood_private_db_subnet:
  boto_vpc.subnet_present:
    - name: private_db_subnet-dogwood_qa
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.5.5.0/24

create_dogwood_qa_internet_gateway:
  boto_vpc.internet_gateway_present:
    - name: dogwood_qa-igw
    - vpc_name: {{ VPC_NAME }}

create_dogwood_qa_routing_table:
  boto_vpc.route_table_present:
    - name: dogwood_qa-route_table
    - vpc_name: {{ VPC_NAME }}
    - subnet_names:
        - public-dogwood_qa
    - routes:
        - destination_cidr_block: 0.0.0.0/0
          internet_gateway_name: dogwood_qa-igw

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
        - ip_protocol: ssh
          cidr_ip:
            - 10.0.0.0/16
            - 10.5.0.0/16

create_dogwood_consul_security_group:
  boto_secgroup.present:
    - name: consul-dogwood_qa
    - description: Access rules for Consul cluster in {{ VPC_NAME }} stack
    - vpc_name: {{ VPC_NAME }}
    - rules:
        - ip_protocol: tcp
          from_port: 8500
          to_port: 8500
          source_group_name: default
        - ip_protocol: udp
          from_port: 8500
          to_port: 8500
          source_group_name: default
        - ip_protocol: tcp
          from_port: 8600
          to_port: 8600
          source_group_name: default
        - ip_protocol: udp
          from_port: 8600
          to_port: 8600
          source_group_name: default
        - ip_protocol: tcp
          from_port: 8301
          to_port: 8301
          source_group_name: default
        - ip_protocol: udp
          from_port: 8301
          to_port: 8301
          source_group_name: default

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
