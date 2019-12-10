{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}
{% set pkg_version = salt.pkg.version('elasticsearch') | default('') %}

elastic_stack:
  elasticsearch:
    configuration_settings:
      discovery:
        zen.hosts_provider: ec2
      cluster.name: {{ ENVIRONMENT }}
      discovery.ec2.tag.escluster: {{ ENVIRONMENT }}
      network.host: ['_eth0:ipv4_', '_lo:ipv4_']
      {% if version and version.split('.')[0]|int > 6 %}
      cluster.initial_master_nodes:
        - elasticsearch.service.consul
      {% endif %}
    plugins:
      - name: discovery-ec2
