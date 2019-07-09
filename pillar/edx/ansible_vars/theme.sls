{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set purpose = salt.grains.get('purpose', 'xpro-qa') %}
{% set environment = salt.grains.get('environment', 'xpro-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set purpose_data = env_settings.environments[environment].purposes[purpose] %}

edx:
  ansible_vars:
    EDXAPP_ENABLE_COMPREHENSIVE_THEMING: true
    EDXAPP_COMPREHENSIVE_THEME_SOURCE_REPO: '{{ purpose_data.versions.theme_source_repo }}'
    EDXAPP_COMPREHENSIVE_THEME_VERSION: {{ purpose_data.versions.theme }}
    edxapp_theme_source_repo: '{{ purpose_data.versions.theme_source_repo }}'
    edxapp_theme_version: {{ purpose_data.versions.theme }}
    EDXAPP_COMPREHENSIVE_THEME_DIRS:
      - /edx/app/edxapp/themes/
    {# multivariate #}
    edxapp_theme_name: '{{ purpose_data.versions.theme_name }}'
    {# multivariate #}
    EDXAPP_DEFAULT_SITE_THEME: '{{ purpose_data.versions.theme_name }}'