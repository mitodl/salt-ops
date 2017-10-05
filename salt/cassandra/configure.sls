include:
  - .service

{% for dirname in ['/var/lib/cassandra/commitlog', '/var/lib/cassandra/data'] %}
{{ dirname }}:
  file.directory:
    - makedirs: True
    - user: cassandra
    - group: cassandra
    - recurse:
        - user
        - group
{% endfor %}

create_cassandra_server_config_file:
  file.managed:
    - name: /etc/cassandra/cassandra.yaml
    - contents: |
        {{ salt.pillar.get('cassandra:configuration')|yaml(False)|indent(8) }}
    - onchanges_in:
        - service: datastax_cassandra_running

create_cassandra_gossip_properties_file:
  file.managed:
    - name: /etc/cassandra/cassandra-rackdc.properties
    - contents: |
        prefer_local=true
        dc={{ salt.grains.get('environment') }}
        rack={{ salt.grains.get('ec2:availability_zone') }}
    - onchanges_in:
        - service: datastax_cassandra_running
