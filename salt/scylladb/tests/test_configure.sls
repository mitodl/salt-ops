ensure_configuration_file_exists:
  testinfra.file:
    - name: /etc/scylla/scylla.yaml
    - exists: True
    - is_file: True
