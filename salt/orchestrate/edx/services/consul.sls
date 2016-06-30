deploy_consul_nodes:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/consul_map.yml
        parallel: True

resize_consul_node_root_partitions:
  salt.state:
    - tgt: 'roles:consul_server'
    - tgt_type: grain
    - sls: utils.grow_partition

load_pillar_data_on_dogwood_consul_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:consul_server and G@environment:dogwood_qa'
    - tgt_type: compound

populate_mine_with_dogwood_consul_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:consul_server and G@environment:dogwood_qa'
    - tgt_type: compound

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_dogwood_consul_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:consul_server and G@environment:dogwood_qa'
    - tgt_type: compound

build_dogwood_consul_nodes:
  salt.state:
    - tgt: 'G@roles:consul_server and G@environment:dogwood_qa'
    - tgt_type: compound
    - highstate: True
