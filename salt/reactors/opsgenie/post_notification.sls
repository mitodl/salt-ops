post_notification_to_opsgenie:
  local.opsgenie.post_data:
    - tgt: 'roles:master'
    - tgt_type: grain
    - kwarg:
        name: salt.reactor.notification
        api_key: {{ __vault__::secret-operations/global/opsgenie/opsgenie_saltstack_api>data>value }}
        reason: {{ data }}
        action_type: Create
