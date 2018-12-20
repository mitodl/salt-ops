restart_uwsgi_service_low_memory:
  local.cmd.run:
    - tgt: {{ data['id'] }}
    - arg:
        - service uwsgi restart
