{% set minion_id = salt.grains.get('id', '') %}

elastic_stack:
  version: 7.12.0
  elasticsearch:
    configuration_settings:
      cloud.node.auto_attributes: true
      # This is necessary based on this discussion
      # https://discuss.elastic.co/t/discovery-with-ecs-dynamic-initial-master-nodes/183149/9
      {% if '0' in minion_id %}
      cluster.initial_master_nodes:
        - {{ minion_id }}
      node.name: {{ minion_id }}
      {% endif %}
      cluster.routing.allocation.awareness.attributes: aws_availability_zone
      discovery.seed_providers: ec2
      gateway.expected_nodes: 3
      gateway.recover_after_nodes: 2
      gateway.recover_after_time: 5m
      rest.action.multi.allow_explicit_index: false
      xpack.ml.enabled: false
      xpack.monitoring.collection.enabled: false
      xpack.security.enabled: false
    plugins:
      - name: discovery-ec2
        config:
          aws:
            region: us-east-1
