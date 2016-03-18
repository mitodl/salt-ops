execute_salt_cloud_logging_map:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run /etc/salt/cloud.maps.d/logging-map.yml parallel=True

build_elasticsearch_nodes:
  salt.state:
    - tgt: 'roles:elasticsearch'
    - tgt_type: grain
    - highstate: True

build_kibana_nodes:
  salt.state:
    - tgt: 'roles:kibana'
    - tgt_type: grain
    - highstate: True

populate_mine_with_elasticsearch_data:
  salt.function:
    - name: mine.update
    - tgt: '*'

build_fluentd_nodes:
  salt.state:
    - tgt: 'roles:fluentd'
    - tgt_type: grain
    - highstate: True
