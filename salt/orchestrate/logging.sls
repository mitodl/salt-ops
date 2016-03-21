{% for profile in ['elasticsearch', 'kibana', 'fluentd'] %}
ensure_instance_profile_exists_for_{{ profile }}:
  boto_iam_role.present:
    - name: {{ profile }}-instance-role
{% endfor %}

deploy_logging_cloud_map:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/logging-map.yml
        parallel: True

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
