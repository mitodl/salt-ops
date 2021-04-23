elastic_stack:
  version: 7.12.0
  elasticsearch:
    configuration_settings:
      discovery:
        zen.hosts_provider: ec2
      discovery.zen.minimum_master_nodes: 2
      gateway.recover_after_nodes: 2
      gateway.expected_nodes: 3
      gateway.recover_after_time: 5m
      rest.action.multi.allow_explicit_index: false
      xpack.security.enabled: false
      xpack.monitoring.collection.enabled: false
      xpack.ml.enabled: false
    plugins:
      - name: discovery-ec2
        config:
          aws:
            region: us-east-1
