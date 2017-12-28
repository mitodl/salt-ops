alert_on_lease_near_expiration:
  local.slack.post_message:
    - tgt: 'roles:master'
    - tgt_type: grain
    - kwarg:
        channel: "#devops"
        message: |
          <@tmacey> <@shaidar> The Vault lease `{{ data['data']['id'] }}` will be expiring at `{{ data['data']['expire_time'] }}`.
          ```
          {{ data['data']|json()|indent(10) }}
          ```
        from_name: "saltbot"
