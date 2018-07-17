restart_reddit_service_low_memory:
  local.cmd.run:
    - tgt: {{ data['id'] }}
    - arg:
        - /usr/local/bin/reddit-restart
