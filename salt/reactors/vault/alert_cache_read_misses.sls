alert_on_cache_read_misses:
  local.slack.post_message:
    - tgt: 'roles:master'
    - tgt_type: grain
    - kwarg:
        channel: "#devops"
        message: |
          <@tmacey> <@shaidar> Vault cached read miss on `{{ data['data']['id'] }}`.
          ```
          {{ data['data']|json()|indent(10) }}
          ```
        from_name: "saltbot"
