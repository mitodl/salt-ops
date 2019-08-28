{% set business_unit = salt.grains.get('business_unit') %}
{% set environment = salt.grains.get('environment') %}

edx:
  mitxpro:
    registration_access_token: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/xpro-registration-access-token>data>value
  tls_key: __vault__::secret-operations/global/xpro_wildcard_cert>data>key
  tls_crt: __vault__::secret-operations/global/xpro_wildcard_cert>data>cert
{% if environment == 'mitxpro-production' %}
  tracking_backups:
    aws_creds:
      access_key: __vault__:cache:aws-mitx/creds/read-write-odl-mitxpro-tracking-backup>data>access_key
      secret_key: __vault__:cache:aws-mitx/creds/read-write-odl-mitxpro-tracking-backup>data>secret_key
{% endif %}
