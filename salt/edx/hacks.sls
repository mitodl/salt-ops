{% set purpose = salt.grains.get('purpose', 'xpro-qa') %}

{% if salt.file.directory_exists('/edx/var/edxapp/staticfiles/studio/templates') %}
ensure_license_selector_template_is_in_expected_location:
  file.copy:
    - name: /edx/var/edxapp/staticfiles/studio/templates/license-selector.underscore.js
    - source: /edx/var/edxapp/staticfiles/studio/templates/license-selector.underscore
    - preserve: True
{% endif %}

{% if salt.file.directory_exists('/edx/var/edxapp/staticfiles/studio/common/templates/components') %}
ensure_system_feedback_template_is_in_expected_location:
  file.copy:
    - name: /edx/var/edxapp/staticfiles/studio/common/templates/components/system-feedback.underscore.js
    - source: /edx/var/edxapp/staticfiles/studio/common/templates/components/system-feedback.underscore
    - preserve: True
{% endif %}

{% if salt.file.directory_exists('/edx/var/edxapp/staticfiles/paragon/static') %}
create_static_assets_subfolder:
  file.directory:
    - name: /edx/var/edxapp/staticfiles/paragon/static/static
    - user: edxapp
    - group: edxapp

copy_select_static_assets_to_static_subfolder:
  module.run:
    - name: file.copy
    - src: /edx/var/edxapp/staticfiles/paragon/static/
    - dst: /edx/var/edxapp/staticfiles/paragon/static/static/
    - recurse: True
    - remove_existing: True
    - preserve: True
{% endif %}

{% if 'mitxpro' in salt.grains.get('environment') %}
add_social_auth_https_redirect_to_lms_production_file:
  file.append:
    - name: /edx/app/edxapp/edx-platform/lms/envs/production.py
    - text: SOCIAL_AUTH_REDIRECT_IS_HTTPS = ENV_TOKENS.get('SOCIAL_AUTH_REDIRECT_IS_HTTPS', True)
{% endif %}

{% if 'residential' in salt.grains.get('purpose') and 'edx-worker' in salt.grains.get('roles') %}
add_cron_task_for_saml_metadata_refresh:
  cron.present:
    - user: edxapp
    - identifier: edx-saml-metadata-refresh
    - comment: Periodically pull the SAML metadata so that it doesn't expire and break edX login
    - name: . /edx/app/edxapp/edxapp_env && /edx/app/edxapp/venvs/edxapp/bin/python /edx/app/edxapp/edx-platform/manage.py lms saml --pull
    - minute: random
    - hour: random
    - dayweek: random
{% endif %}
