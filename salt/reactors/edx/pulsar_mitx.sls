pulsar_mitx:
  local.slack.post_message:
    - tgt: 'roles:master'
    - expr_form: grain
    - kwarg:
        channel: "#devops"
        message: "Hubblestack Pulsar FMI - Detected change - Host:`{{ data['id'] }}` - File modified:`{{ data['path'] }}` - Details: `{{ data }}`"
        from_name: "saltbot"
        api_key: {{ salt.pillar.get('slack_api_token') }}