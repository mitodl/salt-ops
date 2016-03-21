{% for profile, count in [('elasticsearch', 3), ('kibana', 1), ('fluentd', 2)] %}
ensure_instance_profile_exists_for_{{ profile }}:
  salt.function:
    - name: boto_iam.create_role
    - tgt: 'roles: master'
    - tgt_type: grain
    - arg:
        - {{ profile }}-instance-role

{% for num in range(count) %}
build_{{ profile }}_{{ num + 1}}:
  salt.function:
    - name: cloud.profile
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - {{ profile }}
        - {{ profile }}{{ num + 1 }}
    - kwarg:
        iam_profile: {{ profile }}-instance-role
{% endfor %}
{% endfor %}

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
