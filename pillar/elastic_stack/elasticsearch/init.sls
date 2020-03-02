{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}

elastic_stack:
  elasticsearch:
    configuration_settings:
      cluster.name: {{ ENVIRONMENT }}
      discovery.ec2.tag.escluster: {{ ENVIRONMENT }}
      network.host: ['_eth0:ipv4_', '_lo:ipv4_']
      path:
        data: /var/lib/elasticsearch/data
    plugins:
      - name: discovery-ec2
