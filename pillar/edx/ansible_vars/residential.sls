{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set purpose_prefix = purpose.rsplit('-', 1)[0] %}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set purpose_data = env_settings.environments[environment].purposes[purpose] %}
{% if 'live' in purpose %}
  {% set edxapp_git_repo_dir = '/mnt/data/prod_repos' %}
  {% set edxapp_course_about_visibility_permission = 'see_exists' %}
  {% set edxapp_course_catalog_visibility_permission = 'see_exists' %}
  {% set edxapp_course_default_invite_only = False %}
  {% set edxapp_aws_grades_root_path = 'rp-prod/grades' %}
  {% set edxapp_upload_storage_prefix = 'submissions_attachments_prod' %}
  {% set edxapp_log_env_suffix = 'prod' %}
{% else %}
  {% set edxapp_git_repo_dir = '/mnt/data/repos' %}
  {% set edxapp_course_about_visibility_permission = 'staff' %}
  {% set edxapp_course_catalog_visibility_permission = 'staff' %}
  {% set edxapp_course_default_invite_only = True %}
  {% set edxapp_aws_grades_root_path =  'rp-dev/grades' %}
  {% set edxapp_upload_storage_prefix = 'submissions_attachments_dev' %}
  {% set edxapp_log_env_suffix = 'dev' %}
{% endif %}
# Set max memcached object to 2MB
{% set memcached_server_max_value_length = 2097152 %}

{% if environment == 'mitx-production' %}
    {% if 'draft' in purpose %}
    {% set edxapp_google_analytics_account = 'UA-5145472-5' %}
    {% elif 'live' in purpose %}
    {% set edxapp_google_analytics_account = 'UA-5145472-4' %}
    {% endif %}
{% else %}
{% set edxapp_google_analytics_account = '' %}
{% endif %}

edx:
  gitreload:
    gr_dir: /edx/app/gitreload
    gr_repo: github.com/mitodl/gitreload.git
    gr_version: master
    gr_log_dir: "/edx/var/log/gr"
    course_checkout: false
    gr_env:
      PORT: '8095'
      UPDATE_LMS: 'true'
      LOG_LEVEL: debug
      WORKERS: 1
      LOGFILE: "/edx/var/log/gr/gitreload.log"
      VIRTUAL_ENV: /edx/app/edxapp/venvs/edxapp
      EDX_PLATFORM: /edx/app/edxapp/edx-platform
      DJANGO_SETTINGS: production
      LMS_CFG: /edx/etc/lms.yml
      REPODIR: {{ edxapp_git_repo_dir }}
      NUM_THREADS: 3
      GITRELOAD_CONFIG: /edx/app/gitreload/gr.env.json
      LOG_FILE_PATH: /edx/var/log/gr/gitreload.log
    gr_repos: []
    basic_auth:
      location: /edx/app/nginx/gitreload.htpasswd

  ansible_vars:
    common_digicert_base_url: http://dl.cacerts.digicert.com/
    COMMON_ENABLE_AWS_ROLE: False
    EDXAPP_HERMES_ENABLED: False

    XQUEUE_QUEUES:
        'MITx-42.01x': 'https://xserver.mitx.mit.edu/fgxserver'
        'MITx-8371': 'https://xqueue.mitx.mit.edu/qis_xserver'
        # TODO: Are these courses still in use? Can we shut down the xserver instance? (tmacey 2017-03-16)
        'MITx-6.s064x': 'http://127.0.0.1:8051'
        'MITx-7.QBWr': 'http://127.0.0.1:8050'
        'matlab': 'https://mitx.mss-mathworks.com/stateless/mooc/MITx'
        # push queue
        'edX-DemoX': 'http://localhost:8050'
        # pull queues
        'Watcher-MITx-6.0001r': !!null
        'Watcher-MITx-6.00x': !!null
        'open-ended': !!null
        'open-ended-message': !!null
        'test-pull': !!null
        'certificates': !!null
        'mitx-686xgrader': !!null
        'mitx-6S082grader': !!null
    EDXAPP_GOOGLE_ANALYTICS_ACCOUNT: {{ edxapp_google_analytics_account }}
    EDXAPP_YOUTUBE_API_KEY: __vault__::secret-residential/global/edxapp-youtube-api-key>data>value
    EDXAPP_SUPPORT_SITE_LINK: 'https://odl.zendesk.com/hc/en-us/requests/new'
    EDXAPP_CACHE_OPTIONS:
      'server_max_value_length': {{ memcached_server_max_value_length }}
    EDXAPP_SESSION_COOKIE_DOMAIN: .mitx.mit.edu
    EDXAPP_SESSION_COOKIE_NAME: {{ environment }}-{{ purpose }}-session

    EDXAPP_JWT_SIGNING_ALGORITHM: 'RS512'
    EDXAPP_JWT_PRIVATE_SIGNING_JWK: {{ salt.vault.read('secret-' ~  business_unit ~ '/' ~  environment ~ '/jwt-signing-jwk/private-key').data.value }}
    EDXAPP_JWT_PUBLIC_SIGNING_JWK_SET: {{ salt.vault.read('secret-' ~  business_unit ~ '/' ~  environment ~ '/jwt-signing-jwk/public-key').data.value }}
    EDXAPP_SOCIAL_AUTH_SAML_SP_PRIVATE_KEY: __vault__::secret-residential/{{ environment }}/{{ purpose }}/saml-sp-cert>data>key
    EDXAPP_SOCIAL_AUTH_SAML_SP_PUBLIC_CERT: __vault__::secret-residential/{{ environment }}/{{ purpose }}/saml-sp-cert>data>value

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

    EDXAPP_PRIVATE_REQUIREMENTS:
      {% if not ('koa' in grains.get('edx_codename')) %}
      # For Harvard courses. Peer instruction XBlock.
      # edX comment in `configuration' repo at
      # https://github.com/edx/configuration/blob/e7433e03313ffc86a3cfd046c5178ec587841c19/playbooks/roles/edxapp/defaults/main.yml#L528
      # says:
      # "Need it from github until we can land https://github.com/ubc/ubcpi/pull/167 upstream."
      - name: git+https://github.com/edx/ubcpi.git@3c4b2cdc9f595ab8cdb436f559b56f36638313b6#egg=ubcpi-xblock
        extra_args: -e
      # Vector Drawing and ActiveTable XBlocks (Davidson)
      - name: git+https://github.com/open-craft/xblock-vectordraw.git@76976425356dfc7f13570f354c0c438db84c2840#egg=xblock-vectordraw==0.3.0
        extra_args: -e
      - name: git+https://github.com/open-craft/xblock-activetable.git@013003aa3ce28f0ae03b8227dc3a6daa4e19997d#egg=xblock-activetable
        extra_args: -e
      - name: git+https://github.com/edx/edx-zoom.git@37c323ae93265937bf60abb92657318efeec96c5#egg=edx-zoom
        extra_args: -e
      {% endif %}
      # MITx Residential XBlocks
      - name: edx-sga==0.11.0
      - name: rapid-response-xblock==0.0.7
      - name: git+https://github.com/mitodl/edx-git-auto-export.git@v0.2#egg=edx-git-auto-export
        extra_args: -e
      - name: git+https://github.com/Stanford-Online/xblock-in-video-quiz@release/v0.1.7#egg=xblock-in-video-quiz
        extra_args: -e
      - name: xblock-image-modal==0.4.2
      # Python client for Sentry
      - name: raven
      # edX EOX core plugin for Sentry
      - name: eox-core[sentry]
      - name: git+https://github.com/raccoongang/xblock-pdf.git@8d63047c53bc8fdd84fa7b0ec577bb0a729c215f#egg=xblock-pdf
        extra_args: -e
      # edx-proctoring fork to accomodate ProctorTrack
      - name: git+https://github.com/mitodl/edx-proctoring.git@mitx/juniper#egg=edx_proctoring

    # Start ProctorTrack settings
    EDXAPP_PROCTORING_SETTINGS:
      MUST_BE_VERIFIED_TRACK: false

    EDXAPP_PROCTORING_BACKENDS:
      DEFAULT: "proctortrack"
      "null": {}
      "proctortrack":
        client_id: __vault__::secret-{{ business_unit }}/{{ environment }}/proctortrack>data>client_id
        client_secret: __vault__::secret-{{ business_unit }}/{{ environment }}/proctortrack>data>client_secret
        base_url: __vault__::secret-{{ business_unit }}/{{ environment }}/proctortrack>data>base_url
    EDXAPP_JWT_AUDIENCE: "mitx_jwt"
    EDXAPP_LMS_ISSUER: "https://{{ purpose_data.domains.lms }}/oauth2"
    # End ProctorTrack settings
    
    # Enable Secure flag on cookies for browser SameSite restrictions
    EDXAPP_CSRF_COOKIE_SECURE: true
    EDXAPP_SESSION_COOKIE_SECURE: true

    ### Koa settings ###
    # Related keys/values can be removed once all envs are on Koa
    # EDXAPP_ENABLE_EXPORT_GIT: true
    ###############
    EDXAPP_LMS_ENV_EXTRA:
      EMAIL_USE_DEFAULT_FROM_FOR_BULK: True
      CANVAS_BASE_URL: __vault__::secret-{{ business_unit }}/{{ environment}}/canvas>data>base_url
      CANVAS_ACCESS_TOKEN: __vault__::secret-{{ business_unit }}/{{ environment}}/canvas>data>access_token
      FEATURES:
        AUTH_USE_CAS: False
        ALLOW_PUBLIC_ACCOUNT_CREATION: True
        DISABLE_HONOR_CERTIFICATES: True
        SKIP_EMAIL_VALIDATION: True
        ENABLE_VIDEO_UPLOAD_PIPELINE: False # Koa default is False. Remove
        ENABLE_COMBINED_LOGIN_REGISTRATION: True # Koa default is True. Remove
        ENABLE_OAUTH2_PROVIDER: True
        ENABLE_THIRD_PARTY_AUTH: True
        ENABLE_CANVAS_INTEGRATION: True
        ENABLE_INSTRUCTOR_BACKGROUND_TASKS: True
        RESTRICT_ENROLL_NO_ATSIGN_USERNAMES: true
        RESTRICT_ENROLL_SOCIAL_PROVIDERS:
          - mit-kerberos
        ENABLE_THIRD_PARTY_ONLY_AUTH: True
      REMOTE_GRADEBOOK:
        URL: __vault__::secret-{{ business_unit }}/{{ environment }}/remote_gradebook>data>url
        DEFAULT_NAME: !!null
      SECRET_KEY: __vault__:gen_if_missing:secret-residential/global/edxapp-lms-django-secret-key>data>value
      REMOTE_GRADEBOOK_USER: __vault__::secret-{{ business_unit }}/{{ environment }}/remote_gradebook>data>user
      REMOTE_GRADEBOOK_PASSWORD: __vault__::secret-{{ business_unit }}/{{ environment }}/remote_gradebook>data>password
      MONGODB_LOG:
        db: gitlog_{{ purpose_suffix }}
        host: mongodb-master.service.consul
        user: __vault__:cache:mongodb-{{ environment }}/creds/gitlog-{{ purpose }}>data>username
        password: __vault__:cache:mongodb-{{ environment }}/creds/gitlog-{{ purpose }}>data>password
        replicaset: rs0
        readPreference: "nearest"
      SOCIAL_AUTH_SAML_SP_PRIVATE_KEY: __vault__::secret-residential/{{ environment }}/{{ purpose }}/saml-sp-cert>data>key
      SOCIAL_AUTH_SAML_SP_PUBLIC_CERT: __vault__::secret-residential/{{ environment }}/{{ purpose }}/saml-sp-cert>data>value
      EOX_CORE_SENTRY_INTEGRATION_DSN: __vault__::secret-residential/{{ environment }}{{ purpose }}/sentry>data>dsn
      EOX_CORE_SENTRY_IGNORED_ERRORS: []

    EDXAPP_CMS_ENV_EXTRA:
      ADDL_INSTALLED_APPS:
        - ubcpi
        - git_auto_export
        - imagemodal
      FEATURES:
        AUTH_USE_CAS: False
        ENABLE_GIT_AUTO_EXPORT: True
        ENABLE_EXPORT_GIT: True
        ENABLE_OAUTH2_PROVIDER: True
      SECRET_KEY: __vault__:gen_if_missing:secret-residential/global/edxapp-lms-django-secret-key>data>value

    NGINX_SSL_CIPHERS: "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"
