datadog:
  integrations:
    consul:
      settings:
        instances:
          - url: http://localhost:8500
            catalog_checks: yes
            new_leader_checks: yes
