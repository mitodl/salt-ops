#!jinja|yaml|gpg

# Obtain the grains for one of the elasticsearch nodes
{% set hosts = [] %}
{% for host, grains in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:elasticsearch and G@environment:operations', fun='grains.item', tgt_type='compound'
    ).items() %}
{% do hosts.append(grains['external_ip']) %}
{% endfor %}

elasticsearch:
  version: '5.x'
  lookup:
    elastic_stack: True
    configuration_settings:
      cluster.name: mitx_ops_cluster
      discovery.zen.minimum_master_nodes: 3
      discovery.ec2.tag.role: elasticsearch
      gateway.recover_after_nodes: 3
      gateway.expected_nodes: 5
      gateway.recover_after_time: 5m
      repositories:
        s3:
          bucket: mitx-elasticsearch-backups
          region: us-east-1
      discovery:
        zen.hosts_provider: ec2
      cloud.node.auto_attributes: true
      network.host: [_eth0_, _lo_]
    products:
      elasticsearch: 5.x
  plugins:
    - name: discovery-ec2
      config:
        aws:
          region: us-east-1
    - name: repository-s3

beacons:
  service:
    elasticsearch:
      onchangeonly: True
    disable_during_state_run: True
