{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
edx:
  ansible_vars:
    EDXAPP_EXTRA_MIDDLEWARE_CLASSES: [] # Worth keeping track of in case we need to take advantage of it
    EDXAPP_ENABLE_READING_FROM_MULTIPLE_HISTORY_TABLES: False
    EDXAPP_LMS_ENV_EXTRA:
      CANVAS_BASE_URL: https://mit.test.instructure.com
      CANVAS_ACCESS_TOKEN: __vault__::secret-{{ business_unit }}/{{ environment}}/canvas-access-token>data>value
      FEATURES:
        ENABLE_CANVAS_INTEGRATION: True
