#!jinja|yaml|gpg

{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set BUSINESS_UNIT = salt.grains.get('business_unit', 'residential') %}

rabbitmq:
  vhosts:
  {% for purpose in env_settings['environments'][ENVIRONMENT].purposes %}
    - name: /xqueue_{{ purpose|replace('-', '_') }}
      state: present
    - name: /celery_{{ purpose|replace('-', '_') }}
      state: present
  {% endfor %}
