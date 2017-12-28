alert_on_lease_near_expiration:
  local.slack.post_message:
    - tgt: 'roles:master'
    - expr_form: grain
    - kwarg:
        channel: "#devops"
        message: |
          @channel The Vault lease `{{ data['id'] }}` will be expiring at `{{ data['expire_time'] }}`.
          ```
          {{ data|json()|indent(10) }}
          ```
        from_name: "saltbot"
