inotify_mitx:
  local.slack.post_message:
    - tgt: 'roles:master'
    - expr_form: grain
    - kwarg:
        channel: "#devops"
        message: "inotify FIM - Detected change - Host:`{{ data['id'] }}` - File modified:`{{ data['path'] }}` - Details: `{{ data }}`"
        from_name: "saltbot"