#!jinja|yaml|gpg

datadog:
  api_key: __vault__::secret-operations/global/datadog-api-key>data>value
  overrides:
    config:
      tags: roles:{{ salt.grains.get('roles', ['not_set']) | join(', ') }}, environment:{{ salt.grains.get('environment', 'not_set') }}
      log_to_syslog: 'no'
