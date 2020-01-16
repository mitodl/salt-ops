{% set ENVIRONMENT = salt.grains.get('environment') %}

elastic_stack:
  elasticsearch:
    configuration_settings:
      cluster.name: {{ ENVIRONMENT }}
      discovery.ec2.tag.escluster: {{ ENVIRONMENT }}
      gateway.recover_after_nodes: 3
      gateway.expected_nodes: 5
      gateway.recover_after_time: 5m
      cloud.node.auto_attributes: true
      network.host: [_eth0_, _lo_]
      path.data: /var/lib/elasticsearch/data
      discovery.seed_providers: ec2
    plugins:
      - name: discovery-ec2
      - name: repository-s3

    # There seems to be a bug in
    # salt.states.elasticsearch.index_template_present, which causes it to fail
    # without a message, so we're going to update index templates manually until
    # it's sorted out. This is where you would specify the template:
    #
    # index_templates:
    #   - name: logstash
    #     definition:
    #       template: logstash-*
    #       settings:
    #         index:
    #           refresh_interval: 5s
    #           number_of_shards: 5
    #           number_of_replicas: 1
    #       mappings:
    #         fluentd:
    #           dynamic_templates:
    #             - strings:
    #                 match_mapping_type: string
    #                 mapping:
    #                   type: text
    #                   fields:
    #                     raw:
    #                       type: keyword
    #                       ignore_above: 256

beacons:
  service:
    elasticsearch:
      onchangeonly: True
    disable_during_state_run: True
