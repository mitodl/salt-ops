{% set SIX_MONTHS = '4368h' %}

enable_transit_secret_backend:
  vault.secret_backend_enabled:
    - backend_type: transit
    - description: Backend to provide encryption, hashing, and randomness as a service

enable_mitx_aws_secret_backend:
  vault.secret_backend_enabled:
    - backend_type: aws
    - mount_point: aws-mitx
    - description: Backend to dynamically create IAM credentials
    - ttl_max: {{ SIX_MONTHS }}
    - ttl_default: {{ SIX_MONTHS }}
    - lease_max: {{ SIX_MONTHS }}
    - lease_default: {{ SIX_MONTHS }}

{% for unit in salt.pillar.get('business_units', []) %}
enable_generic_backend_for_{{ unit }}:
  vault.secret_backend_enabled:
    - backend_type: generic
    - mount_point: secret-{{ unit }}
    - description: Secrets storage for values pertaining to {{ unit }}
{% endfor %}
