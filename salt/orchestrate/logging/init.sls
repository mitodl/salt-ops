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
        roles:
          - elasticsearch
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

resize_root_partitions_on_elasticsearch_nodes:
  salt.state:
    - tgt: 'G@roles:elasticsearch and G@environment:operations'
    - tgt_type: compound
    - sls: utils.grow_partition

load_pillar_data_on_logging_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
      tgt: 'P@roles:(elasticsearch|kibana|fluentd) and G@environment:operations'
      tgt_type: compound
    - require:
      - salt: deploy_logging_cloud_map

populate_mine_with_logging_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'P@roles:(elasticsearch|kibana|fluentd) and G@environment:operations'
    - tgt_type: compound
    - require:
      - salt: load_pillar_data_on_logging_nodes

build_logging_nodes:
  salt.state:
    - tgt: 'P@roles:(elasticsearch|kibana|fluentd) and G@environment:operations'
    - tgt_type: compound
    - highstate: True

# Obtain the grains for one of the elasticsearch nodes
{% set hosts = [] %}
{% for host, grains in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:elasticsearch and G@environment:operations', fun='grains.item', tgt_type='compound'
    ).items() %}
{% do hosts.append(grains['external_ip']) %}
{% endfor %}
# PUT the mapper template into the ES _template index
put_elasticsearch_mapper_template:
  http.query:
    - name: http://{{ hosts }}:9200/_template/logstash
    - data: '
      {
        "template":   "logstash-*",
        "settings" : {
          "index.refresh_interval" : "5s"
        },
        "mappings": {
          "_default_": {
            "_all": {
              "enabled": false
            },
            "dynamic_templates": [
              {
                "strings": {
                  "match_mapping_type": "string",
                  "mapping": {
                    "type": "string",
                    "fields": {
                      "raw": {
                        "type":  "string",
                        "index": "not_analyzed",
                        "ignore_above": 256
                      }
                    }
                  }
                }
              }
            ]
          }
        }
      }'
    - method: PUT
    - status: 200

{% set hosts = [] %}
{% for host, grains in salt.saltutil.runner(
    'mine.get',
    tgt='roles:kibana', fun='grains.item', tgt_type='grain'
    ).items() %}
{% do hosts.append(grains['external_ip']) %}
{% endfor %}
register_kibana_dns:
  boto_route53.present:
    - name: logs.odl.mit.edu
    - value: {{ hosts }}
    - zone: odl.mit.edu.
    - record_type: A

{% set hosts = [] %}
{% for host, grains in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:fluentd and G@roles:aggregator', fun='grains.item', tgt_type='compound'
    ).items() %}
{% do hosts.append(grains['external_ip']) %}
{% endfor %}
register_log_aggregator_dns:
  boto_route53.present:
    - name: log-input.odl.mit.edu
    - value: {{ hosts }}
    - zone: odl.mit.edu.
    - record_type: A

{% set hosts = [] %}
{% for host, grains in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:fluentd and G@roles:aggregator', fun='grains.item', tgt_type='compound'
    ).items() %}
{% do hosts.append(grains['ec2:local_ipv4']) %}
{% endfor %}
register_log_aggregator_internal_dns:
  boto_route53.present:
    - name: log-input.private.odl.mit.edu
    - value: {{ hosts }}
    - zone: private.odl.mit.edu.
    - record_type: A
