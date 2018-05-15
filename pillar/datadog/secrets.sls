#!jinja|yaml|gpg

datadog:
  api_key: __vault__::secret-operations/global/datadog-api-key>data>value
