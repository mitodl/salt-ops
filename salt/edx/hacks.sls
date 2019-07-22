{% set purpose = salt.grains.get('purpose', 'xpro-qa') %}

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
