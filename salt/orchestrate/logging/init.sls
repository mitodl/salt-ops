{% set ENVIRONMENT = 'operations' %}
{% for profile in ['elasticsearch', 'kibana', 'fluentd'] %}
ensure_instance_profile_exists_for_{{ profile }}:
  boto_iam_role.present:
    - name: {{ profile }}-instance-role
{% endfor %}
load_elasticsearch_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/elasticsearch.conf
    - source: salt://orchestrate/aws/cloud_profiles/elasticsearch.conf

load_fluentd_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/fluentd.conf
    - source: salt://orchestrate/aws/cloud_profiles/fluentd.conf

load_kibana_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/kibana.conf
    - source: salt://orchestrate/aws/cloud_profiles/kibana.conf

generate_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/logging-map.yml
    - source: salt://orchestrate/aws/map_templates/logging-map.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: {{ ENVIRONMENT }}
        securitygroupid: sg-0a994772
        subnetids:
          - subnet-13305e2e
    - require:
        - file: load_elasticsearch_cloud_profile
        - file: load_fluentd_cloud_profile
        - file: load_kibana_cloud_profile

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
    - require:
      - file: generate_cloud_map_file

load_pillar_data_on_logging_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'P@roles:(elasticsearch|kibana|fluentd) and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
      - salt: deploy_logging_cloud_map

populate_mine_with_logging_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'P@roles:(elasticsearch|kibana|fluentd) and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
      - salt: load_pillar_data_on_logging_nodes

build_logging_nodes:
  salt.state:
    - tgt: 'P@roles:(elasticsearch|kibana|fluentd) and G@environment:'
    - tgt_type: compound
    - highstate: True

format_data_drive:
  salt.function:
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - blockdev.formatted
    - kwarg:
        name: /dev/xvdb
        fs_type: ext4
    - require:
        - salt: build_logging_nodes

mount_data_drive:
  salt.function:
    - tgt: 'G@roles:elasticsearch and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - mount.mounted
    - kwarg:
        name: /var/lib/elasticsearch
        device: /dev/xvdb
        fstype: ext4
        mkmnt: True
        opts: 'relatime,user'
    - require:
        - salt: format_data_drive

# Elasticsearch Curator is used for elasticsearch snapshots
install_elasticsearch_curator:
  pkg.installed:
    - name: elasticsearch-curator
    - require:
      - salt: build_logging_nodes
