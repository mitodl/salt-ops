{% set datasources = salt.pillar.get('redash:datasources', []) %}
{% for source in datasources %}
manage_datasource_settings_for_{{ source.name }}:
  cmd.script:
    - source: salt://apps/redash/templates/ensure_datasource_configured.sh
    - template: jinja
    - context:
        ds: {{ source }}
{% endfor %}
