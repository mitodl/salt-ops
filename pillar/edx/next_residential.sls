{% from "shared/edx/mitx.jinja" import edx with context %}

edx:
  config:
    repo: https://github.com/mitodl/configuration.git
    branch: open-release/ginkgo.master
  ansible_vars:
    {# multivariate #}
    EDXAPP_COMPREHENSIVE_THEME_DIRS:
      - /edx/app/edxapp/themes/
    EDXAPP_IMPORT_EXPORT_BUCKET: "mitx-storage-{{ salt.grains.get('purpose') }}-{{ salt.grains.get('environment') }}"
    EDXAPP_LMS_ENV_EXTRA:
      FIELD_OVERRIDE_PROVIDERS:
        - courseware.student_field_overrides.IndividualStudentOverrideProvider
      COURSE_MODE_DEFAULTS:
        bulk_sku: !!null
        currency: 'usd'
        description: !!null
        expiration_datetime: !!null
        min_price: 0
        name: 'Honor'
        sku: !!null
        slug: 'honor'
        suggested_prices: ''
