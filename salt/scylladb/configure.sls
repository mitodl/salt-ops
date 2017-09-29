{% for dirname in ['/var/lib/scylla/commitlog', '/var/lib/scylla/data'] %}
{{ dirname }}:
  file.directory:
    - makedirs: True
    - user: scylla
    - group: scylla
    - recurse:
        - user
        - group
{% endfor %}

create_scylladb_server_config_file:
  file.managed:
    - name: /etc/scylla/scylla.yaml
    - contents: |
        {{ salt.pillar.get('scylladb:configuration')|yaml(False)|indent(8) }}

create_scylladb_gossip_properties_file:
  file.managed:
    - name: /etc/scylla/cassandra-rackdc.properties
    - contents: |
        prefer_local=true
        dc={{ salt.grains.get('environment') }}
        rack={{ salt.grains.get('ec2:availability_zone') }}

create_scylla_io_config_file:
  file.managed:
    - name: /etc/scylla.d/io.conf
    - makedirs: True
    - contents: 'SEASTAR_IO="--max-io-requests=6 --num-io-queues=1"'

scylladb_service_enabled:
  service.running:
    - name: scylla-server
    - enable: True
    - onchanges:
        - file: create_scylladb_server_config_file
        - file: create_scylla_io_config_file
