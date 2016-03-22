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

populate_mine_with_logging_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'P@roles:(elasticsearch|kibana|fluentd)'
    - tgt_type: compound

build_logging_nodes:
  salt.state:
    - tgt: 'P@roles:(elasticsearch|kibana|fluentd)'
    - tgt_type: compound
    - highstate: True

{% set kibana_host = '' %}
{% for host, grains in salt.mine.get(
    kibana1, 'grains.item', expr_form='compound'
    ).items() %}
{% set kibana_host = grains['external_ip'] %}
{% endfor %}
register_kibana_dns:
  boto_route53.present:
    - name: logs.odl.mit.edu
    - value: {{ kibana_host }}
    - zone: odl.mit.edu.
    - record_type: A
