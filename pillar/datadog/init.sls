#!jinja|yaml|gpg

datadog:
  api_key: __vault__::secret-operations/global/datadog-api-key>data>value
  config:
    tags:
      - roles:{{ salt.grains.get('roles', ['not_set']) | join(', ') }}
      - environment:{{ salt.grains.get('environment', 'not_set') }}
      - minion:{{ salt.grains.get('id') }}
    log_to_syslog: 'no'
    apm_config:
      enabled: True
    hostname: {{ salt.grains.get('id') }}
