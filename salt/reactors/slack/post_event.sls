post_event_to_slack:
  local.slack.post_message:
    - tgt: 'roles:master'
    - tgt_type: grain
    - kwarg:
        channel: "#devops"
        message: "SaltStack Event {{ tag }}:`{{ data }}`"
        from_name: "saltbot"
