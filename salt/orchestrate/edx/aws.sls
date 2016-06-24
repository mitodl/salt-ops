# Make sure that instance profiles exist for node types so that
# they can be granted access via permissions attached to those
# profiles because it's easier than managing IAM keys
{% for profile in ['consul', 'mongodb', 'rabbitmq', 'edx'] %}
ensure_instance_profile_exists_for_{{ profile }}:
  boto_iam_role.present:
    - name: {{ profile }}-instance-role
{% endfor %}

create_edx_security_group:
  boto_secgroup.present:
    - name: edx-dogwood_qa
    - description: Access rules for EdX instances
    - vpc_name: Dogwood QA
    - rules:
        - ip_protocol: http
          from_port: 80
          to_port: 80
          cidr_ip: 0.0.0.0/0
        - ip_protocol: https
          from_port: 443
          to_port: 443
          cidr_ip: 0.0.0.0/0

create_mongodb_security_group:
  boto_secgroup.present:
    - name: mongodb-dogwood_qa
    - description: Grant access to Mongo from EdX instances
    - vpc_name: Dogwood QA
    - rules:
        - ip_protocol: tcp
          from_port: 27017
          to_port: 27017
          source_group_name: edx
        - ip_protocol: ssh
          cidr_ip:
            - 10.0.0.0/16
            - 10.5.0.0/16

create_consul_security_group:
  boto_secgroup.present:
    - name: consul-dogwood_qa
    - description: Access rules for Consul cluster in Dogwood QA stack
    - vpc_name: Dogwood QA
    - rules:
        - ip_protocol: tcp
          from_port: 8500
          to_port: 8500
          source_group_name: default-dogwood_qa
        - ip_protocol: udp
          from_port: 8500
          to_port: 8500
          source_group_name: default-dogwood_qa
        - ip_protocol: tcp
          from_port: 8600
          to_port: 8600
          source_group_name: default-dogwood_qa
        - ip_protocol: udp
          from_port: 8600
          to_port: 8600
          source_group_name: default-dogwood_qa
        - ip_protocol: tcp
          from_port: 8301
          to_port: 8301
          source_group_name: default-dogwood_qa
        - ip_protocol: udp
          from_port: 8301
          to_port: 8301
          source_group_name: default-dogwood_qa

create_consul_security_group:
  boto_secgroup.present:
    - name: consul-operations
    - description: Access rules for Consul cluster in operations VPC
    - vpc_name: mitodl-operations-services
    - rules:
        - ip_protocol: tcp
          from_port: 8500
          to_port: 8500
          source_group_name: default-odl-ops
        - ip_protocol: udp
          from_port: 8500
          to_port: 8500
          source_group_name: default-odl-ops
        - ip_protocol: tcp
          from_port: 8600
          to_port: 8600
          source_group_name: default-odl-ops
        - ip_protocol: udp
          from_port: 8600
          to_port: 8600
          source_group_name: default-odl-ops
        - ip_protocol: tcp
          from_port: 8301
          to_port: 8301
          source_group_name: default-odl-ops
        - ip_protocol: udp
          from_port: 8301
          to_port: 8301
          source_group_name: default-odl-ops

vault_security_group:
  boto_secgroup.present:
    - name: vault-operations
    - description: ACL for vault in operations VPC
    - vpc_name: mitodl-operations-services
    - rules:
        - ip_protocol: tcp
          from_port: 8200
          to_port: 8200
          cidr_ip:
            - 10.0.0.0/16
            - 10.5.0.0/16
