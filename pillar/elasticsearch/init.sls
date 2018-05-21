{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}

elasticsearch:
  version: '6.x'
  lookup:
    elastic_stack: True
    configuration_settings:
      discovery:
        zen.hosts_provider: ec2
      cluster.name: {{ ENVIRONMENT }}
      discovery.ec2.tag.escluster: {{ ENVIRONMENT }}
      network.host: [_eth0_, _lo_]
    products:
      elasticsearch: '6.x'
  plugins:
    - name: discovery-ec2
