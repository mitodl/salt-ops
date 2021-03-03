include:
  - .service

# FIXME: ^^^ this starts the service before it's configured.

ensure_absence_of_default_toml_configuration:
  file.absent:
    - name: /etc/vector/vector.toml

manage_vector_configuration_file:
  file.managed:
    - name: /etc/vector/vector.yaml
    - contents: |
        {{ salt.pillar.get('vector:configuration')|yaml(False)|indent(8) }}
    - onchanges_in:
      - service: vector_service_running
