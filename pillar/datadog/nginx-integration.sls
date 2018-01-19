#!jinja|yaml

{% set roles = salt.grains.get('roles'| join(', ')) %}

datadog:
  integrations:
    nginx:
      settings:
        instances:
          - nginx_status_url: http://127.0.0.1/nginx_status
            tags:
              - {{ roles }}
