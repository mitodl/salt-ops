{% set env_settings = salt.file.read(salt.cp.cache_file("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml"))|load_yaml %}
{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}

edx:
  ansible_vars:
    EDXAPP_JWT_SIGNING_ALGORITHM: 'RS512'
    EDXAPP_JWT_PRIVATE_SIGNING_JWK: {{ salt.vault.read('secret-' ~  business_unit ~ '/' ~  environment ~ '/jwt-signing-jwk/private-key').data.value }}
    EDXAPP_JWT_PUBLIC_SIGNING_JWK_SET: {{ salt.vault.read('secret-' ~  business_unit ~ '/' ~  environment ~ '/jwt-signing-jwk/public-key').data.value }}
