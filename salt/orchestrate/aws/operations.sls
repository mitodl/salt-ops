create_operations_consul_security_group:
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

create_vault_security_group:
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
