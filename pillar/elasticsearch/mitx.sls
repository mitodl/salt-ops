{% set ENVIRONMENT = salt.grains.get('environment') %}
elasticsearch:
  version: '1.7'
  lookup:
    pkgs:
      - openjdk-8-jre-headless
    verify_package: False
    elastic_stack: False
    configuration_settings:
      discovery:
        type: ec2
      discovery.ec2.tag.escluster: {{ ENVIRONMENT }}
      gateway.recover_after_nodes: 2
      gateway.expected_nodes: 3
      discovery.zen.minimum_master_nodes: 2
      discovery.zen.ping.multicast.enabled: 'false'
      cluster.name: {{ ENVIRONMENT }}
      repositories:
        s3:
          bucket: {{ ENVIRONMENT }}-elasticsearch-backups
          region: us-east-1
      network.host: [_eth0_, _lo_]
    products:
      elasticsearch: '1.7'
  plugins:
    - name: cloud-aws
      location: elasticsearch/elasticsearch-cloud-aws/2.7.1
