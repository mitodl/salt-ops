pulsar_mitx:
  local.slack.post_message:
    - tgt: {{ data['id'] }}
    - kwarg:
       channel: "#devops"
       message: "Hubblestack Pulsar FMI - Detected change - Host:`{{ data['id'] }}` - File modified:`{{ data['path'] }}` - User:`{{ data['stats']['user'] }}`"
       from_name: "saltbot"
       api_key: {{ salt.pillar.get('slack_api_token') }}