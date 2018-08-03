{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'operations') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', env_data.vpc_name) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}
{% set network_prefix = env_data.network_prefix %}
{% set cidr_block = '{}.0.0/16'.format(network_prefix) %}
{% set env_nets = [] %}
{% for env, settings in env_settings.environments.items() %}
{% do env_nets.append('{}.0.0/22'.format(settings.network_prefix)) %}
{% endfor %}
{% set ODL_WIRED_CIDR = '18.124.0.0/16' %}
{% set ODL_WIRELESS_CIDR = '18.40.64.0/19' %}
{% set MIT_VPN_0_CIDR = '18.100.0.0/16' %}
{% set MIT_VPN_1_CIDR = '18.101.0.0/16' %}

create_{{ ENVIRONMENT }}_vpc:
  boto_vpc.present:
    - name: {{ VPC_NAME }}
    - cidr_block: {{ cidr_block }}
    - instance_tenancy: default
    - dns_support: True
    - dns_hostnames: True
    - tags:
        Name: {{ VPC_NAME }}
        business_unit: {{ BUSINESS_UNIT }}

create_{{ ENVIRONMENT }}_public_subnet_1:
  boto_vpc.subnet_present:
    - name: public1-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.0.1.0/24
    - availability_zone: us-east-1d
    - tags:
        Name: public1-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}

create_{{ ENVIRONMENT }}_public_subnet_2:
  boto_vpc.subnet_present:
    - name: public2-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.0.2.0/24
    - availability_zone: us-east-1b
    - tags:
        Name: public2-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}

create_{{ ENVIRONMENT }}_public_subnet_3:
  boto_vpc.subnet_present:
    - name: public3-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - cidr_block: 10.0.3.0/24
    - availability_zone: us-east-1c
    - tags:
        Name: public3-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}

manage_{{ ENVIRONMENT }}_routing_table:
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
    - tags:
        Name: {{ ENVIRONMENT }}-route_table
        business_unit: {{ BUSINESS_UNIT }}

create_{{ ENVIRONMENT }}_consul_security_group:
  boto_secgroup.present:
    - name: consul-{{ ENVIRONMENT }}
    - description: Access rules for Consul cluster in operations VPC
    - vpc_name: {{ VPC_NAME }}
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
          cidr_ip: {{ env_nets }}
          {# WAN cluster interface #}

create_elasticsearch_security_group:
  boto_secgroup.present:
    - name: elasticsearch-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for elasticsearch servers
    - rules:
        - ip_protocol: tcp
          from_port: 9200
          to_port: 9200
          cidr_ip: {{ env_nets }}
        - ip_protocol: tcp
          from_port: 9300
          to_port: 9400
          source_group_name: elasticsearch-{{ ENVIRONMENT }}
    - tags:
        Name: elasticsearch-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}


create_{{ ENVIRONMENT }}_consul_agent_security_group:
  boto_secgroup.present:
    - name: consul-agent-{{ ENVIRONMENT }}
    - description: Access rules for Consul agent in {{ VPC_NAME }} stack
    - vpc_name: {{ VPC_NAME }}
    - rules:
        - ip_protocol: tcp
          from_port: 8301
          to_port: 8301
          source_group_name: consul-agent-{{ ENVIRONMENT }}
        - ip_protocol: udp
          from_port: 8301
          to_port: 8301
          source_group_name: consul-agent-{{ ENVIRONMENT }}
        - ip_protocol: tcp
          from_port: 8301
          to_port: 8301
          source_group_name: consul-{{ ENVIRONMENT }}
        - ip_protocol: udp
          from_port: 8301
          to_port: 8301
          source_group_name: consul-{{ ENVIRONMENT }}
    - require:
        - boto_vpc: create_{{ ENVIRONMENT }}_vpc
        - boto_secgroup: create_{{ ENVIRONMENT }}_consul_security_group
    - tags:
        Name: consul-agent-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}

create_vault_security_group:
  boto_secgroup.present:
    - name: vault-{{ ENVIRONMENT }}
    - description: ACL for vault in operations VPC
    - vpc_name: {{ VPC_NAME }}
    - rules:
        - ip_protocol: tcp
          from_port: 8200
          to_port: 8200
          source_group_name: default
    - tags:
        Name: vault-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}

create_webapp_security_group:
  boto_secgroup.present:
    - name: webapp-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for web servers
    - rules:
        - ip_protocol: tcp
          from_port: 80
          to_port: 80
          cidr_ip:
            - 0.0.0.0/0
            - '::/0'
        - ip_protocol: tcp
          from_port: 443
          to_port: 443
          cidr_ip:
            - 0.0.0.0/0
            - '::/0'
    - tags:
        Name: webapp-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}

create_webapp_odl_vpn_security_group:
  boto_secgroup.present:
    - name: webapp-odl-vpn-{{ ENVIRONMENT }}
    - vpc_name: {{ VPC_NAME }}
    - description: ACL for web servers accessible only from ODL and VPN
    - rules:
        - ip_protocol: tcp
          from_port: 443
          to_port: 443
          cidr_ip:
            - {{ ODL_WIRED_CIDR }}
            - {{ ODL_WIRELESS_CIDR }}
            - {{ MIT_VPN_0_CIDR }}
            - {{ MIT_VPN_1_CIDR }}
    - tags:
        Name: webapp-odl-vpn-{{ ENVIRONMENT }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        Environment: {{ ENVIRONMENT }}
