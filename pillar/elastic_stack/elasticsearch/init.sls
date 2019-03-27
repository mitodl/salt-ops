{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}

elastic_stack:
  elasticsearch:
    version: '6.x'
    configuration_settings:
      discovery:
        zen.hosts_provider: ec2
      cluster.name: {{ ENVIRONMENT }}
      discovery.ec2.tag.escluster: {{ ENVIRONMENT }}
      network.host: ['_eth0:ipv4_', '_lo:ipv4_']
    plugins:
      - name: discovery-ec2
