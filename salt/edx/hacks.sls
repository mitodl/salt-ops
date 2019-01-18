ensure_license_selector_template_is_in_expected_location:
  file.copy:
    - name: /edx/var/edxapp/staticfiles/studio/templates/license-selector.underscore.js
    - source: /edx/var/edxapp/staticfiles/studio/templates/license-selector.underscore
    - user: edxapp
    - group: www-data

ensure_system_feedback_template_is_in_expected_location:
  file.copy:
    - name:/edx/var/edxapp/staticfiles/studio/common/templates/components/system-feedback.underscore.js
    - source: /edx/var/edxapp/staticfiles/studio/common/templates/components/system-feedback.underscore
    - user: edxapp
    - group: www-data
