{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}

elastic_stack:
  elasticsearch:
    configuration_settings:
      cloud.node.auto_attributes: true
      cluster.name: {{ ENVIRONMENT }}
      discovery.ec2.tag.escluster: {{ ENVIRONMENT }}
      gateway.expected_nodes: 3
      gateway.recover_after_nodes: 2
      gateway.recover_after_time: 5m
      network.host: ['_site_', '_local_']
      path:
        data: /var/lib/elasticsearch/data
    plugins:
      - name: discovery-ec2
