{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set DEFAULT_FEEDBACK_EMAIL = 'mitx-support@mit.edu' %}
{% set DEFAULT_FROM_EMAIL = 'mitx-support@mit.edu' %}
{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set purpose_data = env_settings.environments[environment].purposes[purpose] %}
{% set LMS_DOMAIN = purpose_data.domains.lms %}
{% set CMS_DOMAIN = purpose_data.domains.cms %}
{% set EDXAPP_LMS_ISSUER = "https://{}/oauth2".format(LMS_DOMAIN) %}
{% set EDXAPP_CMS_ISSUER = "https://{}/oauth2".format(CMS_DOMAIN) %}
{% set TIME_ZONE = 'America/New_York' %}
{% set THEME_NAME = 'mitx-theme' %}
{% set roles = salt.grains.get('roles', 'edx-live') %}
{% set MYSQL_HOST = 'mysql.service.consul' %}
{% set MYSQL_PORT = 3306 %}
{% set MONGODB_HOST = 'mongodb-master.service.consul' %}
{% set MONGODB_PORT = 27017 %}
{% set cache_configs = env_settings.environments[environment].backends.elasticache %}
{% if cache_configs is mapping %}
  {% set cache_configs = [cache_configs] %}
{% endif %}
{% set xqwatcher_xqueue_creds = salt.vault.read(
    'secret-{business_unit}/{env}/xqwatcher-xqueue-django-auth-{purpose}'.format(
        business_unit=business_unit,
        env=environment,
        purpose=purpose)) %}
{% set edxapp_xqueue_creds = salt.vault.read(
    'secret-{business_unit}/{env}/edxapp-xqueue-django-auth-{purpose}'.format(
        business_unit=business_unit,
        env=environment,
        purpose=purpose)) %}

{% if 'live' in purpose %}
  {% set edxapp_git_repo_dir = '/mnt/data/prod_repos' %}
  {% set edxapp_course_about_visibility_permission = 'see_exists' %}
  {% set edxapp_course_catalog_visibility_permission = 'see_exists' %}
  {% set edxapp_aws_grades_root_path = 'rp-prod/grades' %}
  {% set edxapp_upload_storage_prefix = 'submissions_attachments_prod' %}
  {% set edxapp_log_env_suffix = 'prod' %}
{% else %}
  {% set edxapp_git_repo_dir = '/mnt/data/repos' %}
  {% set edxapp_course_about_visibility_permission = 'staff' %}
  {% set edxapp_course_catalog_visibility_permission = 'staff' %}
  {% set edxapp_aws_grades_root_path =  'rp-dev/grades' %}
  {% set edxapp_upload_storage_prefix = 'submissions_attachments_dev' %}
  {% set edxapp_log_env_suffix = 'dev' %}
{% endif %}

{% if environment == 'mitx-qa' %}
{% set efs_id = 'fs-6f55af26' %}
{% elif environment == 'mitx-production' %}
{% set efs_id = 'fs-1f27ae56' %}
{% endif %}

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
  {% if 'edx-worker' in roles %}
  playbooks:
    - 'edx-east/worker.yml'
  {% endif %}
  efs_id: {{ efs_id }}

  edxapp:
    GIT_REPO_DIR: {{ edxapp_git_repo_dir }}
    THEME_NAME: 'mitx-theme'
    custom_theme:
      repo: {{ purpose_data.versions.theme_source_repo }}
      branch: {{ purpose_data.versions.theme }}

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
    ### EDXAPP ENVIRONMENT ###
    EDXAPP_MEMCACHE:
      {% for cache_config in cache_configs %}
      {% set cache_purpose = cache_config.get('purpose', 'shared') %}
      {% if cache_purpose in purpose %}
      {% set ELASTICACHE_CONFIG = salt.boto3_elasticache.describe_cache_clusters(cache_config.cluster_id[:20].strip('-'), ShowCacheNodeInfo=True)[0] %}
      {% for host in ELASTICACHE_CONFIG.CacheNodes %}
      - {{ host.Endpoint.Address }}:{{ host.Endpoint.Port }}
      {% endfor %}
      {% endif %}
      {% endfor %}
    ### XQUEUE ENVIRONMENT ###
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
    XQUEUE_LOGGING_ENV: {{ edxapp_log_env_suffix }}
    XQUEUE_DJANGO_USERS:
      {{ edxapp_xqueue_creds.data.username }}: {{ edxapp_xqueue_creds.data.password }}
      {{ xqwatcher_xqueue_creds.data.username }}: {{ xqwatcher_xqueue_creds.data.password }}
    XQUEUE_AWS_ACCESS_KEY_ID: __vault__:cache:aws-mitx/creds/mitx-s3-{{ purpose }}-{{ environment }}>data>access_key
    XQUEUE_AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/mitx-s3-{{ purpose }}-{{ environment }}>data>secret_key
    XQUEUE_BASIC_AUTH_USER: mitx
    XQUEUE_BASIC_AUTH_PASSWORD: __vault__::secret-residential/global/xqueue-password>data>value
    XQUEUE_MYSQL_DB_NAME: xqueue_{{ purpose_suffix }}
    XQUEUE_MYSQL_HOST: {{ MYSQL_HOST }}
    XQUEUE_MYSQL_PASSWORD: __vault__:cache:mysql-{{ environment }}/creds/xqueue-{{ purpose }}>data>password
    XQUEUE_MYSQL_PORT: {{ MYSQL_PORT }}
    XQUEUE_MYSQL_USER: __vault__:cache:mysql-{{ environment }}/creds/xqueue-{{ purpose }}>data>username
    XQUEUE_UPLOAD_BUCKET: mitx-grades-{{ purpose }}-{{ environment }}
    xqueue_source_repo: {{ purpose_data.versions.xqueue_source_repo }}
    xqueue_version: {{ purpose_data.versions.xqueue }}
    ########## END XQUEUE ########################################

    ########## START THEMING ########################################
    EDXAPP_ENABLE_COMPREHENSIVE_THEMING: true
    EDXAPP_COMPREHENSIVE_THEME_SOURCE_REPO: '{{ purpose_data.versions.theme_source_repo }}'
    EDXAPP_COMPREHENSIVE_THEME_VERSION: {{ purpose_data.versions.theme }}
    edxapp_theme_source_repo: '{{ purpose_data.versions.theme_source_repo }}'
    edxapp_theme_version: {{ purpose_data.versions.theme }}
    EDXAPP_COMPREHENSIVE_THEME_DIRS:
      - /edx/app/edxapp/themes/
    {# multivariate #}
    edxapp_theme_name: {{ THEME_NAME }}
    {# multivariate #}
    EDXAPP_DEFAULT_SITE_THEME: {{ THEME_NAME }}
    ########## END THEMING ########################################

    ################################################################################
    #################### Forum Settings ############################################
    ################################################################################
    FORUM_API_KEY: __vault__::secret-residential/global/forum-api-key>data>value
    FORUM_ELASTICSEARCH_HOST: "nearest-elasticsearch.query.consul"
    FORUM_MONGO_USER: __vault__:cache:mongodb-{{ environment }}/creds/forum-{{ purpose }}>data>username
    FORUM_MONGO_PASSWORD: __vault__:cache:mongodb-{{ environment }}/creds/forum-{{ purpose }}>data>password
    FORUM_MONGO_HOSTS:
      - {{ MONGODB_HOST }}
    FORUM_MONGO_PORT: {{ MONGODB_PORT }}
    {# multivariate #}
    FORUM_MONGO_DATABASE: forum_{{ purpose_suffix }}
    FORUM_RACK_ENV: "production"
    FORUM_SINATRA_ENV: "production"
    FORUM_USE_TCP: True
    forum_source_repo: {{ purpose_data.versions.forum_source_repo }}
    forum_version: {{ purpose_data.versions.forum }}
    ########## END FORUM ########################################

    EDXAPP_MYSQL_CSMH_DB_NAME: edxapp_csmh_{{ purpose_suffix }}
    EDXAPP_MYSQL_CSMH_HOST: {{ MYSQL_HOST }}
    EDXAPP_MYSQL_CSMH_PASSWORD: __vault__:cache:mysql-{{ environment }}/creds/edxapp-csmh-{{ purpose }}>data>password
    EDXAPP_MYSQL_CSMH_PORT: {{ MYSQL_PORT }}
    EDXAPP_MYSQL_CSMH_USER: __vault__:cache:mysql-{{ environment }}/creds/edxapp-csmh-{{ purpose }}>data>username

    EDXAPP_DEFAULT_FILE_STORAGE: 'storages.backends.s3boto.S3BotoStorage'
    EDXAPP_AWS_STORAGE_BUCKET_NAME: mitx-storage-{{ purpose }}-{{ environment }}
    EDXAPP_IMPORT_EXPORT_BUCKET: "mitx-storage-{{ salt.grains.get('purpose') }}-{{ salt.grains.get('environment') }}"
    edxapp_course_static_dir: /edx/var/edxapp/course_static_dummy {# private variable, used to hack around the fact that we mount our course data via a shared file system (tmacey 2017-03-16) #}
    {# residential only, set this in order to verride the `fs_root` setting for module/content store, need to understand more fully how this gets used in GITHUB_REPO_ROOT (tmacey 2017/03/17) #}
    edxapp_course_data_dir: {{ edxapp_git_repo_dir }}
    EDXAPP_CELERY_WORKERS:
      - queue: low
        service_variant: cms
        concurrency: 5
        monitor: True
      - queue: default
        service_variant: cms
        concurrency: 4
        monitor: True
      - queue: high
        service_variant: cms
        concurrency: 3
        monitor: True
      - queue: low
        service_variant: lms
        concurrency: 5
        monitor: True
      - queue: default
        service_variant: lms
        concurrency: 4
        monitor: True
      - queue: high
        service_variant: lms
        concurrency: 3
        monitor: True
      - queue: high_mem
        service_variant: lms
        concurrency: 1
        monitor: False
        max_tasks_per_child: 1

    EDXAPP_GOOGLE_ANALYTICS_ACCOUNT: {{ edxapp_google_analytics_account }}
    EDXAPP_YOUTUBE_API_KEY: __vault__::secret-residential/global/edxapp-youtube-api-key>data>value
    EDXAPP_LMS_AUTH_EXTRA:
      REMOTE_GRADEBOOK_USER: __vault__::secret-{{ business_unit }}/{{ environment }}/remote_gradebook>data>user
      REMOTE_GRADEBOOK_PASSWORD: __vault__::secret-{{ business_unit }}/{{ environment }}/remote_gradebook>data>password
    EDXAPP_BUGS_EMAIL: mitx-support@mit.edu
    EDXAPP_COMMENTS_SERVICE_KEY: __vault__::secret-residential/global/forum-api-key>data>value
    EDXAPP_COMMENTS_SERVICE_URL: "http://localhost:4567"
    EDXAPP_LMS_ISSUER: "{{ EDXAPP_LMS_ISSUER }}"
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
    EDXAPP_CONTACT_EMAIL: mitx-support@mit.edu
    EDXAPP_DEFAULT_FEEDBACK_EMAIL: "{{ DEFAULT_FEEDBACK_EMAIL }}"
    EDXAPP_DEFAULT_FROM_EMAIL: "{{ DEFAULT_FROM_EMAIL }}"
    EDXAPP_GRADE_BUCKET: mitx-grades-{{ purpose }}-{{ environment }}
    EDXAPP_GRADE_ROOT_PATH: {{ edxapp_aws_grades_root_path }}
    EDXAPP_GRADE_STORAGE_TYPE: S3
    EDXAPP_GIT_REPO_DIR: "{{ edxapp_git_repo_dir }}"
    EDXAPP_PLATFORM_NAME: MITx Residential
    EDXAPP_PLATFORM_DESCRIPTION: 'MITx Residential Online Course Portal'
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
        - name: rapid-response-xblock==0.0.2
    EDXAPP_STATIC_URL_BASE: "https://{{ cloudfront_domain }}/static/"
    EDXAPP_TECH_SUPPORT_EMAIL: mitx-support@mit.edu
    EDXAPP_CMS_ISSUER: "{{ EDXAPP_CMS_ISSUER }}"

    common_feature_flags: &common_feature_flags
      AUTH_USE_CAS: true
      REROUTE_ACTIVATION_EMAIL: mitx-support@mit.edu
      ENABLE_INSTRUCTOR_ANALYTICS: true
      ENABLE_INSTRUCTOR_LEGACY_DASHBOARD: true
      ENABLE_CSMH_EXTENDED: True
      ENABLE_READING_FROM_MULTIPLE_HISTORY_TABLES: True

    common_env_config: &common_env_config
      ADDL_INSTALLED_APPS:
        - ubcpi
      ADMINS:
      - ['MITx Stacktrace Recipients', 'cuddle-bunnies@mit.edu']
      BOOK_URL: ""
      SERVER_EMAIL: mitxmail@mit.edu
      TIME_ZONE_DISPLAYED_FOR_DEADLINES: "{{ TIME_ZONE }}"

    EDXAPP_CODE_JAIL_LIMITS:
      REALTIME: 3
      CPU: 3
      FSIZE: 1048576
      PROXY: 0
      VMEM: 536870912

    EDXAPP_LMS_ENV_EXTRA:
      <<: *common_env_config
      BULK_EMAIL_DEFAULT_FROM_EMAIL: mitx-support@mit.edu
      COURSE_ABOUT_VISIBILITY_PERMISSION: "{{ edxapp_course_about_visibility_permission }}"
      COURSE_CATALOG_VISIBILITY_PERMISSION: "{{ edxapp_course_catalog_visibility_permission }}"
      ALLOW_ALL_ADVANCED_COMPONENTS: True
      FEATURES:
        <<: *common_feature_flags
        ALLOW_COURSE_STAFF_GRADE_DOWNLOADS: true
        ENABLE_INSTRUCTOR_REMOTE_GRADEBOOK_CONTROLS: true
        ENABLE_S3_GRADE_DOWNLOADS: true
        ENABLE_SHOPPING_CART: true
        ENABLE_SYSADMIN_DASHBOARD: true
        ENABLE_INSTRUCTOR_EMAIL: true
      REMOTE_GRADEBOOK:
        URL: __vault__::secret-{{ business_unit }}/{{ environment }}/remote_gradebook>data>url
        DEFAULT_NAME: !!null
      OAUTH_OIDC_ISSUER: "{{ EDXAPP_LMS_ISSUER }}"
      STUDENT_FILEUPLOAD_MAX_SIZE: "20 * 1024 * 1024"
      LOGGING_ENV: lms-{{ edxapp_log_env_suffix}}
    EDXAPP_CMS_ENV_EXTRA:
      <<: *common_env_config
      FEATURES:
        <<: *common_feature_flags
        STAFF_EMAIL: mitx-support@mit.edu
    EDXAPP_ENABLE_MOBILE_REST_API: True
    EDXAPP_ENABLE_SYSADMIN_DASHBOARD: True
    EDXAPP_FILE_UPLOAD_STORAGE_BUCKET_NAME: mitx-storage-{{ purpose }}-{{ environment }}
    EDXAPP_FILE_UPLOAD_STORAGE_PREFIX: "{{ edxapp_upload_storage_prefix }}"
    OAUTH_OIDC_ISSUER: "{{ EDXAPP_CMS_ISSUER }}"
    LOGGING_ENV: cms-{{ edxapp_log_env_suffix }}
    EDXAPP_XQUEUE_DJANGO_AUTH:
      username: {{ edxapp_xqueue_creds.data.username }}
      password: {{ edxapp_xqueue_creds.data.password }}
