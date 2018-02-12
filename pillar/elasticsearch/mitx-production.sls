{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set lan_nodes = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:elasticsearch and G@environment:{}'.format(ENVIRONMENT),
    fun='grains.item',
    tgt_type='compound').items() %}
{% do lan_nodes.append('{0}:9200'.format(addr['ec2:local_ipv4'])) %}
{% endfor %}

elasticsearch:
  lookup:
    pkgs:
      - openjdk-7-jre-headless
    verify_package: False
    configuration_settings:
      discovery.zen.ping.unicast.hosts: {{ lan_nodes }}
      discovery.zen.ping.multicast.enabled: 'false'
      cluster.name: {{ ENVIRONMENT }}
      repositories:
        s3:
          bucket: {{ ENVIRONMENT }}-elasticsearch-backups
          region: us-east-1
      network.host: [_eth0_, _lo_]
    products:
      elasticsearch: '1.5'
  plugins:
    - name: cloud-aws
      location: elasticsearch/elasticsearch-cloud-aws/2.5.1
