elastic_stack:
  version: 7.12.0
  elasticsearch:
    configuration_settings:
      cloud.node.auto_attributes: true
      cluster.routing.allocation.awareness.attributes: aws_availability_zone
      discovery.seed_providers: ec2
      discovery.zen.minimum_master_nodes: 2
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
