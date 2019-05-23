{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}

edx:
  ansible_vars:
    EDXAPP_EXTRA_MIDDLEWARE_CLASSES: [] # Worth keeping track of in case we need to take advantage of it
    EDXAPP_SESSION_COOKIE_DOMAIN: .mitx.mit.edu
    EDXAPP_SESSION_COOKIE_NAME: {{ environment }}-{{ purpose }}-session
    EDXAPP_CMS_AUTH_EXTRA:
      SECRET_KEY: __vault__:gen_if_missing:secret-residential/global/edxapp-lms-django-secret-key>data>value
    EDXAPP_REGISTRATION_EXTRA_FIELDS:
      confirm_email: "hidden"
      level_of_education: "optional"
      gender: "optional"
      year_of_birth: "optional"
      mailing_address: "hidden"
      goals: "optional"
      honor_code: "required"
      terms_of_service: "hidden"
      city: "hidden"
      country: "hidden"
    EDXAPP_LMS_ENV_EXTRA:
      FEATURES:
        AUTH_USE_CAS: true
        ALLOW_PUBLIC_ACCOUNT_CREATION: True
        SKIP_EMAIL_VALIDATION: True
    EDXAPP_CMS_ENV_EXTRA:
      FEATURES:
        AUTH_USE_CAS: true
