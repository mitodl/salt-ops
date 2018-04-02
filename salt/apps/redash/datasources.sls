{% set redash_env = salt.pillar.get('django:environment') %}
{% set datasources = salt.pillar.get('redash:data_sources', []) %}
{% for source in datasources %}
manage_datasource_settings_for_{{ source.name }}:
  cmd.script:
    - source: salt://apps/redash/templates/ensure_datasource_configured.sh
    - template: jinja
    - cwd: /opt/redash
    - runas: redash
    - env: {{ redash_env }}
    - context:
        ds: {{ source }}
{% endfor %}
