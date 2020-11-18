{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set business_unit = salt.grains.get('business_unit', 'mitxpro') %}
{% set purpose = salt.grains.get('purpose', 'xpro-qa') %}
{% set environment = salt.grains.get('environment', 'mitxpro-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set bucket_prefix = env_data.secret_backends.aws.bucket_prefix %}
{% set support_email = 'support@xpro.mit.edu' %}
{% set heroku_xpro_env_url_mapping = {
    'sandbox': 'https://xpro-ci.odl.mit.edu',
    'xpro-qa': 'https://xpro-rc.odl.mit.edu',
    'xpro-production': 'https://xpro.mit.edu'
  } %}
{% set heroku_env = heroku_xpro_env_url_mapping['{}'.format(purpose)] %}

edx:
  ansible_vars:
    EDXAPP_EDX_API_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/edx-api-key>data>value
    EDXAPP_SESSION_COOKIE_DOMAIN: .xpro.mit.edu
    EDXAPP_SESSION_COOKIE_NAME: {{ environment }}-{{ purpose }}-session
    EDXAPP_COMMENTS_SERVICE_URL: "http://localhost:4567"
    EDXAPP_COMMENTS_SERVICE_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/global/forum-api-key>data>value
    EDXAPP_IDA_LOGOUT_URI_LIST: ['{{ heroku_env }}/logout']
    # Enable Secure flag on cookies for browser SameSite restrictions
    {% if 'juniper' in grains.get('edx_codename') %}
    EDXAPP_CSRF_COOKIE_SECURE: true
    EDXAPP_SESSION_COOKIE_SECURE: true
    {% endif %}
    EDXAPP_SOCIAL_AUTH_OAUTH_SECRETS:
        mitxpro-oauth2: __vault__::secret-{{ business_unit }}/{{ environment }}/xpro-app-oauth2-client-secret-{{ purpose }}>data>value
    EDXAPP_LMS_ISSUER: https://{{ env_data.purposes[purpose].domains.lms }}/oauth2
    EDXAPP_JWT_AUDIENCE: '{{ business_unit }}-{{ environment }}-key'
    EDXAPP_JWT_SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/jwt-secret-key>data>value
    EDXAPP_JWT_SIGNING_ALGORITHM: 'RS512'
    EDXAPP_JWT_PRIVATE_SIGNING_JWK: __vault__::secret-{{ business_unit }}/{{ environment }}/jwt-signing-jwk/private-key>data>value
    EDXAPP_JWT_PUBLIC_SIGNING_JWK_SET: __vault__::secret-{{ business_unit }}/{{ environment }}/jwt-signing-jwk/public-key>data>value
    EDXAPP_PRIVATE_REQUIREMENTS:
      - name: mitxpro-openedx-extensions==0.2.2
      - name: social-auth-mitxpro==0.4
      - name: git+https://github.com/edx/ubcpi.git@3c4b2cdc9f595ab8cdb436f559b56f36638313b6#egg=ubcpi-xblock
        extra_args: -e
      - name: git+https://github.com/mitodl/edx-git-auto-export.git@v0.2#egg=edx-git-auto-export
      # edX EOX core plugin for Sentry
      - name: eox-core[sentry]
    ### Koa settings ###
    # Related keys/values can be removed once all envs are on Koa
    # EDXAPP_ENABLE_VIDEO_UPLOAD_PIPELINE: True
    # EDXAPP_THIRD_PARTY_AUTH_BACKENDS:
    # - social_auth_mitxpro.backends.MITxProOAuth2
    ###########
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
      ABOUT: "{{ heroku_env }}/about-us"
      CONTACT: "https://xpro.zendesk.com/hc/en-us/requests/new"
      HONOR: "honor-code"
      PRIVACY: "privacy-policy"
      TOS: "terms-of-service"
    EDXAPP_SUPPORT_SITE_LINK: 'https://xpro.zendesk.com/hc'
    EDXAPP_LMS_ENV_EXTRA:
      BULK_EMAIL_DEFAULT_FROM_EMAIL: {{ support_email }}
      COMPLETION_VIDEO_COMPLETE_PERCENTAGE: 0.85
      COMPLETION_BY_VIEWING_DELAY_MS: 1000
      COURSE_ABOUT_VISIBILITY_PERMISSION: staff
      COURSE_CATALOG_VISIBILITY_PERMISSION: staff
      COURSE_MODE_DEFAULTS:
        name: "Audit"
        slug: "audit"
      EMAIL_USE_DEFAULT_FROM_FOR_BULK: True
      MARKETING_SITE_ROOT: {{ heroku_env }}
      MITXPRO_CORE_REDIRECT_ALLOW_RE_LIST: ["^/(admin|auth|login|logout|register|api|oauth2|user_api|heartbeat)", "^/courses/.*/xblock/.*/handler_noauth/outcome_service_handler"]
      THIRD_PARTY_AUTH_BACKENDS: ["social_auth_mitxpro.backends.MITxProOAuth2"]
      # django-session-cookie middleware
      {% if 'juniper' in grains.get('edx_codename') %}
      DCS_SESSION_COOKIE_SAMESITE: 'Strict' # Koa default is accurate. Remove
      DCS_SESSION_COOKIE_SAMESITE_FORCE_ALL: True # Koa default is accurate. Remove
      {% endif %}
      FEATURES:
        REROUTE_ACTIVATION_EMAIL: {{ support_email }}
        ENABLE_VIDEO_UPLOAD_PIPELINE: False
        ENABLE_COMBINED_LOGIN_REGISTRATION: True # Koa default is True. Remove
        ENABLE_MKTG_SITE: True
        ENABLE_OAUTH2_PROVIDER: True
        ENABLE_THIRD_PARTY_AUTH: True
        ALLOW_PUBLIC_ACCOUNT_CREATION: True
        SKIP_EMAIL_VALIDATION: True
      EOX_CORE_SENTRY_INTEGRATION_DSN: __vault__::secret-residential/{{ environment }}{{ purpose }}/sentry>data>dsn
      EOX_CORE_SENTRY_IGNORED_ERRORS: []

    EDXAPP_CMS_ENV_EXTRA:
      ADDL_INSTALLED_APPS:
        - git_auto_export
      COMPLETION_VIDEO_COMPLETE_PERCENTAGE: 0.85
      COMPLETION_BY_VIEWING_DELAY_MS: 1000
      DISABLE_STUDIO_SSO_OVER_LMS: True
      FEATURES:
        STAFF_EMAIL: {{ support_email }}
        REROUTE_ACTIVATION_EMAIL: {{ support_email }}
        ENABLE_GIT_AUTO_EXPORT: true
        ENABLE_EXPORT_GIT: true
        ENABLE_VIDEO_UPLOAD_PIPELINE: True
    EDXAPP_PLATFORM_NAME: MIT xPRO
    EDXAPP_PLATFORM_DESCRIPTION: MIT xPRO Online Course Portal
    EDXAPP_DEFAULT_FEEDBACK_EMAIL: {{ support_email }}
    EDXAPP_DEFAULT_FROM_EMAIL: {{ support_email }}
    EDXAPP_BUGS_EMAIL: {{ support_email }}
    EDXAPP_CONTACT_EMAIL: {{ support_email }}
    EDXAPP_TECH_SUPPORT_EMAIL: {{ support_email }}
