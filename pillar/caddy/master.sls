{% set ENVIRONMENT = salt.grains.get('environment', 'operations') %}

caddy:
  config:
    apps:
      http:
        servers:
          salt_api:
            listen: ':443'
            routes:
              - match:
                  {% if 'qa' in ENVIRONMENT %}
                  - host: salt-qa.odl.mit.edu
                  {% else %}
                  - host: salt-production.odl.mit.edu
                  {% endif %}
                handle:
                  - reverse_proxy: 127.0.0.1:8080
