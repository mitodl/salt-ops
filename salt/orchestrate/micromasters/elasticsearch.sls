{% set VPC_NAME = 'micromasters' %}
{% set VPC_RESOURCE_SUFFIX = VPC_NAME.lower() | replace(' ', '-') %}
{% set VPC_NET_PREFIX = '10.10' %}
{% set ENVIRONMENT = 'micromasters' %}
{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-{}'.format(VPC_RESOURCE_SUFFIX), 'public2-{}'.format(VPC_RESOURCE_SUFFIX), 'public3-{}'.format(VPC_RESOURCE_SUFFIX)])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

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

load_elasticsearch_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/elasticsearch.conf
    - source: salt://orchestrate/aws/cloud_profiles/elasticsearch.conf

generate_elasticsearch_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_elasticsearch_map.yml
    - source: salt://orchestrate/aws/map_templates/elasticsearch.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: {{ ENVIRONMENT }}
        roles:
          - elasticsearch
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'elasticsearch-{}'.format(VPC_RESOURCE_SUFFIX),
            vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-{}'.format(VPC_RESOURCE_SUFFIX),
            vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids }}
        volume_size: 200
        tags:
          escluster: {{ ENVIRONMENT }}
    - require:
        - file: load_elasticsearch_cloud_profile

deploy_elasticsearch_nodes:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_elasticsearch_map.yml
        parallel: True
    - require:
        - file: generate_elasticsearch_cloud_map_file

load_pillar_data_on_{{ ENVIRONMENT }}_elasticsearch_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: deploy_elasticsearch_nodes

populate_mine_with_{{ ENVIRONMENT }}_elasticsearch_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_{{ ENVIRONMENT }}_elasticsearch_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_{{ ENVIRONMENT }}_elasticsearch_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_{{ ENVIRONMENT }}_elasticsearch_data

{% set hosts = [] %}
{% for host, grains in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:elasticsearch and G@environment:{}'.format(ENVIRONMENT), fun='grains.item', tgt_type='compound'
    ).items() %}
{% do hosts.append(grains['external_ip']) %}
{% endfor %}
register_{{ ENVIRONMENT }}-elasticsearch_dns:
  boto_route53.present:
    - name: es.{{ VPC_RESOURCE_SUFFIX }}.odl.mit.edu
    - value: {{ hosts }}
    - zone: odl.mit.edu.
    - record_type: A

build_{{ ENVIRONMENT }}_elasticsearch_nodes:
  salt.state:
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_{{ ENVIRONMENT }}_elasticsearch_nodes
