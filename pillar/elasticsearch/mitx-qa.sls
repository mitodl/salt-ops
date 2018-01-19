{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set lan_nodes = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:elasticsearch and G@environment:{}'.format(ENVIRONMENT),
    fun='grains.item',
    tgt_type='compound').items() %}
{% do lan_nodes.append('{0}:9300-9400'.format(addr['ec2:local_ipv4'])) %}
{% endfor %}

elasticsearch:
  lookup:
    pkgs:
      - openjdk-7-jre-headless
    verify_package: False
    configuration_settings:
      cluster.name: mitx-qa
      discovery.zen.ping.unicast.hosts: {{ lan_nodes }}
      discovery.zen.ping.multicast.enabled: 'false'
      repositories:
        s3:
          bucket: mitx-qa-elasticsearch-backups
          region: us-east-1
    products:
      elasticsearch: '1.7'
  plugins:
    - name: cloud-aws
      location: elasticsearch/elasticsearch-cloud-aws/2.7.1
