ensure_license_selector_template_is_in_expected_location:
  file.copy:
    - name: /edx/var/edxapp/staticfiles/studio/templates/license-selector.underscore.js
    - source: /edx/var/edxapp/staticfiles/studio/templates/license-selector.underscore
    - preserve: True

ensure_system_feedback_template_is_in_expected_location:
  file.copy:
    - name: /edx/var/edxapp/staticfiles/studio/common/templates/components/system-feedback.underscore.js
    - source: /edx/var/edxapp/staticfiles/studio/common/templates/components/system-feedback.underscore
    - preserve: True

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

{% if 'mitxpro' in salt.grains.get('environment') %}
add_social_auth_https_redirect_to_lms_production_file:
  file.append:
    - name: /edx/app/edxapp/edx-platform/lms/envs/production.py
    - text: SOCIAL_AUTH_REDIRECT_IS_HTTPS = ENV_TOKENS.get('SOCIAL_AUTH_REDIRECT_IS_HTTPS', True)

{% for env in ['lms', 'cms'] %}
remove_django_toolbar_from_{{ env }}:
  file.managed:
    - name: /edx/app/edxapp/edx-platform/{{ env }}/envs/private.py
    - user: edxapp
    - group: edxapp
    - create: True
    - mode: 644
    - contents: |
        from .common import INSTALLED_APPS, MIDDLEWARE_CLASSES
        def tuple_without(source_tuple, exclusion_list):
            """Return new tuple excluding any entries in the exclusion list. Needed because tuples
            are immutable. Order preserved."""
            return tuple([i for i in source_tuple if i not in exclusion_list])

        INSTALLED_APPS = tuple_without(INSTALLED_APPS, ['debug_toolbar', 'debug_toolbar_mongo'])
        MIDDLEWARE_CLASSES = tuple_without(MIDDLEWARE_CLASSES, [
            'django_comment_client.utils.QueryCountDebugMiddleware',
            'debug_toolbar.middleware.DebugToolbarMiddleware',
        ])

        DEBUG_TOOLBAR_MONGO_STACKTRACES = False

        import contracts
        contracts.disable_all()
{% endfor %}
{% endif %}
