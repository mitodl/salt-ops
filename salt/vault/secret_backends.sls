{% set SIX_MONTHS = '4368h' %}
{% set pki_ttl = '8760h' %} # ONE_YEAR
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}

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

enable_pki_intermediate_backend:
  vault.secret_backend_enabled:
    - backend_type: pki
    - mount_point: pki-int
    - description: Backend to create certificates signed by our root CA
    - ttl_default: {{ pki_ttl }}
    - connection_config:
        issuing_certificates: 'https://vault.service.consul:8200/vi/pki-int/ca'
        crl_distribution_points: 'https://vault.service.consul:8200/v1/pki-int/crl'

{% for environment in env_settings.environments %}
enable_pki_intermediate_{{ environment }}_backend:
  vault.secret_backend_enabled:
    - backend_type: pki
    - mount_point: pki-{{ environment }}-int-ca
    - description: Backend to create certificates for {{ environment }}
    - ttl_default: {{ pki_ttl }}
    - connection_config:
        issuing_certificates: 'https://vault.service.consul:8200/vi/pki-{{ environment }}-int/ca'
        crl_distribution_points: 'https://vault.service.consul:8200/v1/pki-{{ environment }}-int/crl'
{% endfor %}

{% for unit in salt.pillar.get('business_units', []) %}
enable_generic_backend_for_{{ unit }}:
  vault.secret_backend_enabled:
    - backend_type: generic
    - mount_point: secret-{{ unit }}
    - description: Secrets storage for values pertaining to {{ unit }}
{% endfor %}
