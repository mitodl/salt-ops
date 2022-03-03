{% set vector_config_elements = salt.pillar.get('vector:config_elements') %}

include:
  - .service

ensure_absence_of_default_toml_configuration:
  file.absent:
    - name: /etc/vector/vector.toml

ensure_absence_of_legacy_vector_configuration:
  file.absent:
    - name: /etc/vector/vector.yaml

ensure_absence_of_examples_vector_configurations:
  file.absent:
    - name: /etc/vector/examples

{% set configs = salt.pillar.get('vector:configurations') %}
{% for cfg in configs %}
manage_vector_configurations_{{ cfg }}:
  file.managed:
    - name: /etc/vector/{{ cfg }}.yaml
    - source: salt://vector/templates/{{ cfg }}.yaml.j2
    - template: jinja
    - context:
        config_elements: {{ vector_config_elements }}
    - onchanges_in:
      - service: vector_service_running
{% endfor %}
