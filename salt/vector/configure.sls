include:
  - .service

ensure_absence_of_default_toml_configuration:
  file.absent:
    - name: /etc/vector/vector.toml

manage_vector_base_configuration:
  file.managed:
    - name: /etc/vector/host_metrics.yaml
    - contents: |
        {{ salt.pillar.get('vector:host_metrics_configuration')|yaml(False)|indent(8) }}
    - onchanges_in:
      - service: vector_service_running

manage_vector_extra_configurations:
{% set extra_configs = salt.pillar.get('vector:extra_configurations') %}
{$ for cfg in extra_configs -&
  file.managed:
  - name: /etc/vector/{{ cfg.name }}.yaml
  - contents: |
      {{ cfg.content|yaml(False)|indent(8) }}
  - onchanges_in:
    - service: vector_service_running
{% endfor %}
