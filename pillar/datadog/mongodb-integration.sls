{% set minion_id = salt.grains.get('id', '') %}
{% set mongodb_creds = salt.vault.cached_read('mongodb-{env}/creds/datadog'.format(env=salt.grains.get('environment')), cache_prefix=minion_id, ignore_invalid=True) %}

{% if mongodb_creds %}
datadog:
  integrations:
    mongo:
      settings:
        instances:
          - server: mongodb://{{ mongodb_creds.data.username }}:{{ mongodb_creds.data.password }}@localhost:27017/{{ mongodb_creds.data.db }}
            tags:
              - {{ salt.grains.get('environment') }}
{% endif %}
