restart_reddit_service_low_memory:
  local.cmd.run:
    - tgt: {{ data['id'] }}
    - arg:
        - /usr/local/bin/reddit-restart

post_event_to_slack:
  local.slack.post_message:
    - tgt: 'roles:master'
    - tgt_type: grain
    - kwarg:
        channel: "#devops"
        message: "SaltStack Event {{ tag }}:`{{ data }}`"
        from_name: "saltbot"
