#!jinja|yaml|gpg

datadog:
  api_key: {{ salt.vault.read('secret-operations/global/datadog-api-key').data.value }}
