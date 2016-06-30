{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-operations', 'public2-operations', 'public3-operations'])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

generate_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/operations_consul_map.yml
    - source: salt://orchestrate/aws/map_templates/consul.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: operations
        roles:
          - consul_server
          - service_discovery
          - vault_server
        securitygroupid:
          - {{ salt.boto_secgroup.get_group_id(
            'consul-operations', vpc_name='mitodl-operations-services') }}
          - {{ salt.boto_secgroup.get_group_id(
            'default', vpc_name='mitodl-operations-services') }}
        subnetids: {{ subnet_ids }}

deploy_consul_nodes:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/operations_consul_map.yml
        parallel: True
    - require:
        - file: generate_cloud_map_file

resize_consul_node_root_partitions:
  salt.state:
    - tgt: 'roles:consul_server'
    - tgt_type: grain
    - sls: utils.grow_partition
    - require:
        - salt: deploy_consul_nodes

load_pillar_data_on_dogwood_consul_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:consul_server and G@environment:operations'
    - tgt_type: compound
    - require:
        - salt: resize_consul_node_root_partitions

populate_mine_with_dogwood_consul_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:consul_server and G@environment:operations'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_dogwood_consul_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_dogwood_consul_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:consul_server and G@environment:operations'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_dogwood_consul_data

build_dogwood_consul_nodes:
  salt.state:
    - tgt: 'G@roles:consul_server and G@environment:operations'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: reload_pillar_data_on_dogwood_consul_nodes
