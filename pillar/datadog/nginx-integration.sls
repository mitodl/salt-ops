#!jinja|yaml

datadog:
  integrations:
    nginx:
      settings:
        instances:
          - nginx_status_url: http://127.0.0.1/nginx_status
            tags:
              - roles:{{ salt.grains.get('roles', ['not_set']) | join(', ') }}
              - environment:{{ salt.grains.get('environment', 'not_set') }}
              - minion:{{ salt.grains.get('id') }}
