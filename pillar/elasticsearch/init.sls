{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}

elasticsearch:
  version: '6.x'
  lookup:
    elastic_stack: True
    configuration_settings:
      path:
        data: /var/lib/elasticsearch/data
      discovery:
        zen.hosts_provider: ec2
      cluster.name: {{ ENVIRONMENT }}
      discovery.ec2.tag.escluster: {{ ENVIRONMENT }}
      network.host: ['_eth0:ipv4_', '_lo:ipv4_']
    products:
      elasticsearch: '6.x'
  plugins:
    - name: discovery-ec2
