{% set ENVIRONMENT = salt.grains.get('environment', 'rc-apps') %}
{% set es_hostnames = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:elasticsearch and G@environment:{}'.format(ENVIRONMENT),
    fun='grains.item',
    tgt_type='compound').items() %}
{% do es_hostnames.append(host) %}
{% endfor %}
{% version_data = salt.cp.get_file_str('salt://elastic_stack/version_{}.sls'.format(ENVIRONMENT))|load_yaml %}

elastic_stack:
  elasticsearch:
    configuration_settings:
      discovery:
        zen.hosts_provider: ec2
      cluster.name: {{ ENVIRONMENT }}
      discovery.ec2.tag.escluster: {{ ENVIRONMENT }}
      network.host: ['_eth0:ipv4_', '_lo:ipv4_']
      {% if version_data.elastic_stack.version.startswith('7') %}
      cluster.initial_master_nodes:
        {%- for hostname in es_hostnames %}
        - {{ hostname }}
        {%- endfor -%}
      {% endif %}
    plugins:
      - name: discovery-ec2
