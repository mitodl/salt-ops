{% set purpose = salt.grains.get('purpose', 'xpro-qa') %}
{% set heroku_xpro_env_url_mapping = {
    'sandbox': 'https://xpro-ci.odl.mit.edu',
    'xpro-qa': 'https://xpro-rc.odl.mit.edu',
    'xpro-production': 'https://xpro.mit.edu'
  } %}
{% set heroku_env = heroku_xpro_env_url_mapping['{}'.format(purpose)] %}
{% set JWT_SECRET_KEY = salt.pillar.get('edx:JWT_SECRET_KEY') %}
{% set JWT_ISSUER = salt.pillar.get('edx:JWT_ISSUER') %}
{% set JWT_AUDIENCE = salt.pillar.get('edx:JWT_AUDIENCE') %}
{% set JWT_SECRET_KEY = salt.pillar.get('edx:JWT_SECRET_KEY') %}
{% set JWT_PUBLIC_SIGNING_JWK_SET = salt.pillar.get('edx:JWT_PUBLIC_SIGNING_JWK_SET') %}
{% set JWT_PRIVATE_SIGNING_JWK_SET = salt.pillar.get('edx:JWT_PRIVATE_SIGNING_JWK_SET') %}

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

{% for app in ['lms', 'cms'] %}
add_xpro_base_url_to_{{ app }}_production_file:
  file.append:
    - name: /edx/app/edxapp/edx-platform/{{ app }}/envs/production.py
    - text: XPRO_BASE_URL = '{{ heroku_env }}'
{% endfor %}

add_jwt_auth_to_production_file:
  file.append:
    - name: /edx/app/edxapp/edx-platform/lms/envs/production.py
    - text:
        - JWT_AUTH.update({'JWT_SECRET_KEY': '{{ JWT_SECRET_KEY }}',
        - 'JWT_ISSUER': '{{ JWT_ISSUER }}',
        - 'JWT_AUDIENCE': '{{ JWT_AUDIENCE }}',
        - 'JWT_PUBLIC_SIGNING_JWK_SET': (
            - '{{ JWT_PUBLIC_SIGNING_JWK_SET }}'
        - ),
        - 'JWT_PRIVATE_SIGNING_JWK': (
            - '{{ JWT_PRIVATE_SIGNING_JWK_SET }}'
        - ), })
{% endif %}
