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

scylladb_service_enabled:
  service.running:
    - name: scylla-server
    - enable: True
    - onchanges:
        - file: create_scylladb_server_config_file
