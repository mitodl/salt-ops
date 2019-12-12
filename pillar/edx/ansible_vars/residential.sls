{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
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
      DJANGO_SETTINGS: aws
      REPODIR: {{ edxapp_git_repo_dir }}
      NUM_THREADS: 3
      GITRELOAD_CONFIG: /edx/app/gitreload/gr.env.json
      LOG_FILE_PATH: /edx/var/log/gr/gitreload.log
    gr_repos: []
    basic_auth:
      location: /edx/app/nginx/gitreload.htpasswd

  ansible_vars:
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
    EDXAPP_GOOGLE_ANALYTICS_ACCOUNT: {{ edxapp_google_analytics_account }}
    EDXAPP_YOUTUBE_API_KEY: __vault__::secret-residential/global/edxapp-youtube-api-key>data>value
    EDXAPP_SUPPORT_SITE_LINK: 'https://odl.zendesk.com/hc/en-us/requests/new'
    EDXAPP_CACHE_OPTIONS:
      'server_max_value_length': {{ memcached_server_max_value_length }}
    EDXAPP_SESSION_COOKIE_DOMAIN: .mitx.mit.edu
    EDXAPP_SESSION_COOKIE_NAME: {{ environment }}-{{ purpose }}-session

    EDXAPP_LMS_AUTH_EXTRA:
      SECRET_KEY: __vault__:gen_if_missing:secret-residential/global/edxapp-lms-django-secret-key>data>value
      REMOTE_GRADEBOOK_USER: __vault__::secret-{{ business_unit }}/{{ environment }}/remote_gradebook>data>user
      REMOTE_GRADEBOOK_PASSWORD: __vault__::secret-{{ business_unit }}/{{ environment }}/remote_gradebook>data>password

    EDXAPP_CMS_AUTH_EXTRA:
      SECRET_KEY: __vault__:gen_if_missing:secret-residential/global/edxapp-lms-django-secret-key>data>value

    {# multivariate, only needed for current deployment. will be removed in favor of SAML (tmacey 2017/03/20) #}
    EDXAPP_CAS_ATTRIBUTE_PACKAGE: 'git+https://github.com/mitodl/mitx_cas_mapper#egg=mitx_cas_mapper'
    {# multivariate, only used for current residential #}
    EDXAPP_CAS_SERVER_URL: 'https://cas.mitx.mit.edu/cas'
    {# multivariate, only used for current residential #}
    EDXAPP_CAS_ATTRIBUTE_CALLBACK:
      module: mitx_cas_mapper
      function: populate_user
    {# multivariate, only used for current residential #}
    EDXAPP_CAS_EXTRA_LOGIN_PARAMS:
      provider: touchstone
      appname: MITx

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
        # For Harvard courses:
        # Peer instruction XBlock
        - name: ubcpi-xblock==0.6.4
        # Vector Drawing and ActiveTable XBlocks (Davidson)
        - name: git+https://github.com/open-craft/xblock-vectordraw.git@c57df9d98119fd2ca4cb31b9d16c27333cdc65ca#egg=xblock-vectordraw==0.2.1
          extra_args: -e
        - name: git+https://github.com/open-craft/xblock-activetable.git@e933d41bb86a8d50fb878787ca680165a092a6d5#egg=xblock-activetable
          extra_args: -e
       # MITx Residential XBlocks
        - name: edx-sga==0.8.2
        - name: rapid-response-xblock==0.0.5
        - name: git+https://github.com/mitodl/edx-git-auto-export.git@v0.1#egg=edx-git-auto-export
          extra_args: -e
        - name: git+https://github.com/Stanford-Online/xblock-in-video-quiz@release/v0.1.7#egg=xblock-in-video-quiz
          extra_args: -e
        - name: xblock-image-modal==0.4.2
        # Python client for Sentry
        - name: raven

    EDXAPP_LMS_ENV_EXTRA:
      EMAIL_USE_DEFAULT_FROM_FOR_BULK: True
      FEATURES:
        AUTH_USE_CAS: true
        DISABLE_HONOR_CERTIFICATES: true
        SKIP_EMAIL_VALIDATION: True
        ENABLE_VIDEO_UPLOAD_PIPELINE: False
        ENABLE_COMBINED_LOGIN_REGISTRATION: true
        ENABLE_THIRD_PARTY_AUTH: true
      REMOTE_GRADEBOOK:
        URL: __vault__::secret-{{ business_unit }}/{{ environment }}/remote_gradebook>data>url
        DEFAULT_NAME: !!null
      SOCIAL_AUTH_SAML_SP_PUBLIC_CERT: __vault__::secret-residential/{{ environment }}/{{ purpose_prefix }}/saml-sp-cert>data>value
      SOCIAL_AUTH_SAML_SP_PRIVATE_KEY: __vault__::secret-residential/{{ environment }}/{{ purpose_prefix }}/saml-sp-cert>data>key

    EDXAPP_CMS_ENV_EXTRA:
      ADDL_INSTALLED_APPS:
        - ubcpi
        - git_auto_export
        - imagemodal
      FEATURES:
        AUTH_USE_CAS: true
        ENABLE_GIT_AUTO_EXPORT: true
        ENABLE_EXPORT_GIT: true
