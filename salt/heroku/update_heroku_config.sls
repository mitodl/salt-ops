{% set app_name = salt.pillar.get('heroku:app_name') %}
{% set api_key = salt.pillar.get('heroku:api_key') %}
{% set config_vars = salt.pillar.get('heroku:config_vars') %}

update_heroku_{{ app_name }}_config:
  heroku.update_app_config_vars:
    - name: {{ app_name }}
    - api_key: {{ api_key }}
    - config_vars: {{ config_vars|tojson }}
