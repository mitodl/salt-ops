{% set OCW_ENVIRONMENT = salt.grains.get('ocw-environment') %}
{% set OCW_DEPLOYMENT = salt.grains.get('ocw-deployment') %}
{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set env_data = env_settings.environments.ocw %}
{% set common_name = env_data.purposes['ocw-origin'].domains[OCW_ENVIRONMENT][OCW_DEPLOYMENT][0] %}

letsencrypt:
  overrides:
    email: 'odl-devops@mit.edu'
    common_name: '{{ common_name }}'
    subject_alternative_names: []
