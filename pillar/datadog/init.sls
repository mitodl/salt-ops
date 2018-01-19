#!jinja|yaml|gpg

include:
  - datadog.secrets

datadog:
  overrides:
    config:
      tags: roles:{{ salt.grains.get('roles', ['not_set']) | join(', ') }}, environment:{{ salt.grains.get('environment', 'not_set') }}
      log_to_syslog: 'no'
