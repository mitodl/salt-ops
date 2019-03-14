{% set opsgenie_api_key = salt.vault.read('secret-operations/global/opsgenie/opsgenie_saltstack_api').data.value %}

post_notification_to_opsgenie:
  local.opsgenie.post_data:
    - tgt: 'roles:master'
    - tgt_type: grain
    - kwarg:
        name: salt.reactor.notification
        api_key: {{ opsgenie_api_key }}
        reason: {{ data|tojson }}
        action_type: Create
