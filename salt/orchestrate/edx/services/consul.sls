{% from "orchestrate/aws_env_macro.jinja" import VPC_NAME, VPC_RESOURCE_SUFFIX,
 ENVIRONMENT, BUSINESS_UNIT, subnet_ids with context %}
{% set INSTANCE_COUNT = salt.environ.get('INSTANCE_COUNT', 3) %}

load_consul_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/consul.conf
    - source: salt://orchestrate/aws/cloud_profiles/consul.conf
    - template: jinja

generate_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ VPC_RESOURCE_SUFFIX }}_consul_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        num_instances: {{ INSTANCE_COUNT }}
        service_name: consul
        tags:
          business_unit: {{ BUSINESS_UNIT }}
        environment_name: {{ ENVIRONMENT }}
        roles:
          - consul_server
          - service_discovery
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'consul-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'salt_master-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          - {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids }}
    - require:
        - file: load_consul_cloud_profile

deploy_consul_nodes:
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ VPC_RESOURCE_SUFFIX }}_consul_map.yml
    - parallel: True
    - require:
        - file: generate_cloud_map_file

sync_external_modules_for_consul_nodes:
  salt.function:
    - name: saltutil.sync_all
    - tgt: 'G@roles:consul_server and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound

load_pillar_data_on_mitx_consul_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:consul_server and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: deploy_consul_nodes

populate_mine_with_mitx_consul_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:consul_server and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_mitx_consul_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_mitx_consul_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:consul_server and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_mitx_consul_data

build_mitx_consul_nodes:
  salt.state:
    - tgt: 'G@roles:consul_server and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_mitx_consul_nodes
