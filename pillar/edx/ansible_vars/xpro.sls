{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set business_unit = salt.grains.get('business_unit', 'mitxpro') %}
{% set purpose = salt.grains.get('purpose', 'xpro-qa') %}
{% set environment = salt.grains.get('environment', 'mitxpro-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set bucket_prefix = env_data.secret_backends.aws.bucket_prefix %}
{% set support_email = 'xpro@mit.edu' %}
{% set heroku_xpro_env_url_mapping = {
    'sandbox': 'https://xpro-ci.odl.mit.edu',
    'xpro-qa': 'https://xpro-rc.odl.mit.edu',
    'xpro-production': 'https://xpro.mit.edu'
  } %}
{% set heroku_env = heroku_xpro_env_url_mapping['{}'.format(purpose)] %}

edx:
  ansible_vars:
    EDXAPP_SESSION_COOKIE_DOMAIN: .xpro.mit.edu
    EDXAPP_SESSION_COOKIE_NAME: {{ environment }}-{{ purpose }}-session
    EDXAPP_COMMENTS_SERVICE_URL: "http://localhost:4567"
    EDXAPP_COMMENTS_SERVICE_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/global/forum-api-key>data>value
    EDXAPP_IDA_LOGOUT_URI_LIST: ['{{ heroku_env }}/logout']
    EDXAPP_PRIVATE_REQUIREMENTS:
      - name: mitxpro-openedx-extensions==0.1.0
      - name: social-auth-mitxpro==0.2
      - name: ubcpi-xblock==0.6.4
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
    EDXAPP_MKTG_URLS:
      ROOT: "{{ env_data.purposes[purpose].domains.lms }}"
      ABOUT: "/about-us"
      CONTACT: "https://xpro.zendesk.com/hc/en-us/requests/new"
    EDXAPP_SUPPORT_SITE_LINK: 'https://xpro.zendesk.com/hc'
    EDXAPP_LMS_ENV_EXTRA:
      BULK_EMAIL_DEFAULT_FROM_EMAIL: {{ support_email }}
      COURSE_ABOUT_VISIBILITY_PERMISSION: staff
      COURSE_CATALOG_VISIBILITY_PERMISSION: staff
      COURSE_MODE_DEFAULTS:
        name: "Audit"
        slug: "audit"
      MARKETING_SITE_ROOT: {{ heroku_env }}
      MITXPRO_CORE_REDIRECT_ALLOW_RE_LIST: ["^/(admin|auth|login|logout|register|api|oauth2|user_api|heartbeat)"]
      THIRD_PARTY_AUTH_BACKENDS: ["social_auth_mitxpro.backends.MITxProOAuth2"]
      JWT_AUTH:
        JWT_ISSUER: 'OAUTH_OIDC_ISSUER'
        JWT_AUDIENCE: '{{ business_unit }}-{{ environment }}-key'
        JWT_SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/jwt-secret-key>data>value
        JWT_SIGNING_ALGORITHM: 'RS512'
        JWT_PRIVATE_SIGNING_JWK: __vault__::secret-{{ business_unit }}/{{ environment }}/jwt-signing-jwk/private-key>data>value
        JWT_PUBLIC_SIGNING_JWK_SET: __vault__::secret-{{ business_unit }}/{{ environment }}/jwt-signing-jwk/public-key>data>value
      FEATURES:
        REROUTE_ACTIVATION_EMAIL: {{ support_email }}
        ENABLE_VIDEO_UPLOAD_PIPELINE: False
        ENABLE_COMBINED_LOGIN_REGISTRATION: True
        ENABLE_MKTG_SITE: True
        ENABLE_OAUTH2_PROVIDER: True
        ENABLE_THIRD_PARTY_AUTH: True
        ALLOW_PUBLIC_ACCOUNT_CREATION: True
        SKIP_EMAIL_VALIDATION: True
    EDXAPP_LMS_AUTH_EXTRA:
      SOCIAL_AUTH_OAUTH_SECRETS:
        mitxpro-oauth2: __vault__::secret-{{ business_unit }}/{{ environment }}/xpro-app-oauth2-client-secret-{{ purpose }}>data>value
    EDXAPP_CMS_ENV_EXTRA:
      DISABLE_STUDIO_SSO_OVER_LMS: True
      FEATURES:
        STAFF_EMAIL: {{ support_email }}
        REROUTE_ACTIVATION_EMAIL: {{ support_email }}
        ENABLE_VIDEO_UPLOAD_PIPELINE: True
    EDXAPP_PLATFORM_NAME: MIT xPRO
    EDXAPP_PLATFORM_DESCRIPTION: MIT xPRO Online Course Portal
    EDXAPP_DEFAULT_FEEDBACK_EMAIL: {{ support_email }}
    EDXAPP_DEFAULT_FROM_EMAIL: {{ support_email }}
    EDXAPP_BUGS_EMAIL: {{ support_email }}
    EDXAPP_CONTACT_EMAIL: {{ support_email }}
    EDXAPP_TECH_SUPPORT_EMAIL: {{ support_email }}
