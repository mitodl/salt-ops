#!jinja|yaml

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
    - name: http://{{ hosts[0] }}:9200/_template/logstash
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
