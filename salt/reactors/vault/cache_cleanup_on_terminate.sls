purge_vault_cache_for_terminated_instance:
  local.vault.purge_cache_data:
    - tgt: 'roles:master'
    - tgt_type: grain
    - kwarg:
        prefix: {{ data['name'] }}
