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
