#!jinja|yaml

{% set business_unit = 'mitodl' %}
{% set purpose = 'devstack' %}
{% set environment = salt.environ.get('environment', 'dev-ginkgo') %}
{% set purpose_suffix = 'devstack' %}
{% set edx_platform_branch = 'mitx/ginkgo' %}

{% set xqueue_rabbitmq_username = 'admin' %}
{% set xqueue_rabbitmq_password = 'changeme' %}
{% set edxapp_rabbitmq_username = 'admin' %}
{% set edxapp_rabbitmq_password = 'changeme' %}
{% set admin_mysql_username = 'root' %}
{% set admin_mysql_password = 'changeme' %}
{% set xqueue_mysql_username = 'xqueue_mysql_user' %}
{% set xqueue_mysql_password = 'changeme' %}
{% set edxapp_mysql_username = 'edxapp_mysql_user' %}
{% set edxapp_mysql_password = 'changeme' %}
{% set edxapp_mongodb_username = 'admin' %}
{% set edxapp_mongodb_password = 'changeme' %}
{% set forum_mongodb_username = 'admin' %}
{% set forum_mongodb_password = 'changeme' %}
{% set gitlog_mongodb_username = 'admin'%}
{% set gitlog_mongodb_password = 'changeme' %}
{% set edxapp_xqueue_username = 'edxapp_xqueue_user' %}
{% set edxapp_xqueue_password = 'changeme' %}
{% set xqwatcher_xqueue_username = 'xqwatcher_xqueue_user' %}
{% set xqwatcher_xqueue_password = 'changeme' %}

{% set CELERY_BROKER_PASSWORD = 'changeme' %}
{% set CELERY_BROKER_USER = 'admin' %}
{% set DEFAULT_FEEDBACK_EMAIL = 'mitodl-devstack@example.com' %}
{% set DEFAULT_FROM_EMAIL = 'mitodl-devstack@example.com' %}
{% set GIT_REPO_DIR = '/repo' %}
{% set MONGODB_HOST = 'mongodb.service.consul' %}
{% set MONGODB_MODULESTORE_ENGINE = 'xmodule.modulestore.mongo.MongoModuleStore' %}
{% set MONGODB_PORT = 27017 %}
{% set MONGODB_USE_SSL = False %}
{% set MYSQL_HOST = 'mysql.service.consul' %}
{% set MYSQL_PASSWORD = 'changeme' %}
{% set MYSQL_PORT = 3306 %}
{% set THEME_NAME = 'mitx-theme' %}
{% set TIME_ZONE = 'America/New_York' %}
{% set XQUEUE_PASSWORD = 'changeme' %}
{% set XQUEUE_USER = 'lms' %}
{% set edxapp_log_env = 'sandbox' %}
{% set TLS_KEY_NAME = 'mitodl_devstack' %}
{% set HOST_IP = '192.168.33.10' %}

edx:
  generate_tls_certificate: True
  ansible_env_config:
    TLS_KEY_NAME: {{ TLS_KEY_NAME }}
  config:
    repo: 'https://github.com/mitodl/configuration.git'
    branch: 'open-release/ginkgo.master'
  dependencies:
    os_packages:
      - git
      - libmysqlclient-dev
      - landscape-common
      - libssl-dev
      - python2.7
      - python2.7-dev
      - python-pip
      - python-virtualenv
      - nfs-common
      - postfix
      - memcached
  playbooks:
    - 'mitx_devstack.yml'
  django:
    django_superuser_account: 'devstack'
    django_superuser_password: 'changeme'

  ansible_vars:
    ### COMMON VARS ###
    COMMON_MYSQL_ADMIN_USER: {{ admin_mysql_username }}
    COMMON_MYSQL_ADMIN_PASS: {{ admin_mysql_password }}
    COMMON_MYSQL_MIGRATE_USER: {{ admin_mysql_username }}
    COMMON_MYSQL_MIGRATE_PASS: {{ admin_mysql_password }}

    ### XQUEUE ENVIRONMENT ###
    XQUEUE_BASIC_AUTH_USER: mitx
    XQUEUE_BASIC_AUTH_PASSWORD: {{ XQUEUE_PASSWORD }}
    XQUEUE_DJANGO_USERS:
      {{ edxapp_xqueue_username }}: {{ edxapp_xqueue_password }}
      {{ xqwatcher_xqueue_username }}: {{ xqwatcher_xqueue_password }}
    XQUEUE_LOGGING_ENV: {{ edxapp_log_env }}
    XQUEUE_MYSQL_DB_NAME: xqueue_{{ purpose_suffix }}
    XQUEUE_MYSQL_HOST: {{ MYSQL_HOST }}
    XQUEUE_MYSQL_PASSWORD: {{ xqueue_mysql_password }}
    XQUEUE_MYSQL_PORT: {{ MYSQL_PORT }}
    XQUEUE_MYSQL_USER: {{ xqueue_mysql_username }}
    XQUEUE_RABBITMQ_HOSTNAME: rabbitmq.service.consul
    XQUEUE_RABBITMQ_PASS: {{ xqueue_rabbitmq_password }}
    XQUEUE_RABBITMQ_USER: {{ xqueue_rabbitmq_username }}
    XQUEUE_RABBITMQ_VHOST: /xqueue
    XQUEUE_WORKERS_PER_QUEUE: 2
    xqueue_source_repo: "https://github.com/mitodl/xqueue.git"
    xqueue_version: "master"
    forum_ruby_version: "2.4.1"
    edxapp_theme_source_repo: 'https://github.com/mitodl/mitx-theme.git'
    edxapp_theme_version: 'ginkgo'

    common_debian_pkgs:
      - ntp
      - acl
      - lynx-cur
      - logrotate
      - rsyslog
      - git
      - unzip
      - python2.7
      - python-pip
      - python2.7-dev
    {# residential only #}
    edxapp_course_static_dir: /edx/var/edxapp/course_static_dummy {# private variable, used to hack around the fact that we mount our course data via a shared file system (tmacey 2017-03-16) #}
    {# residential only, set this in order to verride the `fs_root` setting for module/content store, need to understand more fully how this gets used in GITHUB_REPO_ROOT (tmacey 2017/03/17) #}
    edxapp_course_data_dir: {{ GIT_REPO_DIR }}

    EDXAPP_CELERY_WORKERS:
      - queue: low
        service_variant: cms
        concurrency: 1
        monitor: True
      - queue: default
        service_variant: cms
        concurrency: 1
        monitor: True
      - queue: high
        service_variant: cms
        concurrency: 1
        monitor: True
      - queue: low
        service_variant: lms
        concurrency: 1
        monitor: True
      - queue: default
        service_variant: lms
        concurrency: 2
        monitor: True
      - queue: high
        service_variant: lms
        concurrency: 2
        monitor: True
      - queue: high_mem
        service_variant: lms
        concurrency: 1
        monitor: False
        max_tasks_per_child: 1
    EDXAPP_INSTALL_PRIVATE_REQUIREMENTS: true

    ####################################################################
    ############### MongoDB SETTINGS ###################################
    ####################################################################
    {# Settings for Content Store #}
    EDXAPP_MONGO_DB_NAME: contentstore_{{ purpose_suffix }}
    EDXAPP_MONGO_HOSTS: {{ MONGODB_HOST }}
    EDXAPP_MONGO_PASSWORD: {{ edxapp_mongodb_password }}
    EDXAPP_MONGO_PORTS: {{ MONGODB_PORT }}
    EDXAPP_MONGO_USER: {{ edxapp_mongodb_username }}
    EDXAPP_MONGO_USE_SSL: {{ MONGODB_USE_SSL }}

    doc_store_config: &doc_store_config
      db: modulestore_{{ purpose_suffix }}
      host: "{{ MONGODB_HOST }}"
      password: {{ edxapp_mongodb_password }}
      port: {{ MONGODB_PORT }}
      user: {{ edxapp_mongodb_username }}
      collection:  'modulestore'
      readPreference: "nearest"
      ssl: {{ MONGODB_USE_SSL }}
      socketTimeoutMS: 3000
      connectTimeoutMS: 2000

    EDXAPP_LMS_DRAFT_DOC_STORE_CONFIG:
      <<: *doc_store_config

    EDXAPP_LMS_SPLIT_DOC_STORE_CONFIG:
      <<: *doc_store_config

    EDXAPP_CMS_DOC_STORE_CONFIG:
      <<: *doc_store_config


    #####################################################################
    ############### MySQL Config ########################################
    #####################################################################
    EDXAPP_MYSQL_DB_NAME: edxapp_{{ purpose_suffix }}
    EDXAPP_MYSQL_HOST: {{ MYSQL_HOST }}
    EDXAPP_MYSQL_PASSWORD: {{ edxapp_mysql_password }}
    EDXAPP_MYSQL_PORT: {{ MYSQL_PORT }}
    EDXAPP_MYSQL_USER: {{ edxapp_mysql_username }}

    #####################################################################
    ########### Auth Configs ############################################
    #####################################################################
    EDXAPP_CELERY_PASSWORD: {{ edxapp_rabbitmq_password }}
    EDXAPP_CELERY_USER: {{ edxapp_rabbitmq_username }}
    EDXAPP_XQUEUE_DJANGO_AUTH:
      username: {{ edxapp_xqueue_username }}
      password: {{ edxapp_xqueue_password }}
      MONGODB_LOG:
        db: gitlog_{{ purpose_suffix }}
        host: mongodb.service.consul
        user: {{ gitlog_mongodb_username }}
        password: {{ gitlog_mongodb_password }}

    #####################################################################
    ########### Environment Configs #####################################
    #####################################################################
    EDXAPP_BUGS_EMAIL: {{ DEFAULT_FEEDBACK_EMAIL }}
    EDXAPP_CELERY_BROKER_VHOST: /celery
    EDXAPP_CODE_JAIL_LIMITS:
      REALTIME: 3
      CPU: 3
      FSIZE: 1048576
      PROXY: 0
      VMEM: 536870912
    EDXAPP_COMMENTS_SERVICE_URL: "http://localhost:4567"
    EDXAPP_CONTACT_EMAIL: {{ DEFAULT_FEEDBACK_EMAIL }}
    EDXAPP_COMPREHENSIVE_THEME_DIRS:
      - /edx/app/edxapp/themes/
    EDXAPP_ENABLE_CMSH_EXTENDED: False
    EDXAPP_ENABLE_READING_FROM_MULTIPLE_HISTORY_TABLES: False
    EDXAPP_CUSTOM_COURSES_EDX: True
    EDXAPP_DEFAULT_FEEDBACK_EMAIL: "{{ DEFAULT_FEEDBACK_EMAIL }}"
    EDXAPP_DEFAULT_FROM_EMAIL: "{{ DEFAULT_FROM_EMAIL }}"
    EDXAPP_DEFAULT_SITE_THEME: {{ THEME_NAME }}
    EDXAPP_ELASTIC_SEARCH_CONFIG:
      - host: elasticsearch.service.consul
        port: 9200
    EDXAPP_ENABLE_COMPREHENSIVE_THEMING: true
    EDXAPP_ENABLE_MOBILE_REST_API: True
    EDXAPP_ENABLE_OAUTH2_PROVIDER: False
    EDXAPP_ENABLE_SYSADMIN_DASHBOARD: True
    EDXAPP_GIT_REPO_DIR: "{{ GIT_REPO_DIR }}"
    EDXAPP_LMS_BASE: "{{ HOST_IP }}"
    EDXAPP_LMS_BASE_SCHEME: http
    EDXAPP_MKTG_URL_LINK_MAP:
      CONTACT: !!null
      FAQ: !!null
      HONOR: !!null
      PRIVACY: !!null
    EDXAPP_ORA2_FILE_PREFIX: "{{ environment }}-dev/ora2"
    EDXAPP_RABBIT_HOSTNAME: rabbitmq.service.consul
    EDXAPP_TECH_SUPPORT_EMAIL: {{ DEFAULT_FEEDBACK_EMAIL }}
    edxapp_theme_name: {{ THEME_NAME }}
    EDXAPP_TIME_ZONE: "{{ TIME_ZONE }}"

    # Use YAML references (& and *) and hash merge <<: to factor out shared settings
    # see http://atechie.net/2009/07/merging-hashes-in-yaml-conf-files/
    common_feature_flags: &common_feature_flags
      ALLOW_ALL_ADVANCED_COMPONENTS: true
      AUTH_USE_CERTIFICATES: false
      AUTH_USE_CERTIFICATES_IMMEDIATE_SIGNUP: true
      AUTH_USE_MIT_CERTIFICATES: false
      AUTH_USE_MIT_CERTIFICATES_IMMEDIATE_SIGNUP: true
      AUTH_USE_OPENID_PROVIDER: false
      BYPASS_ACTIVATION_EMAIL_FOR_EXTAUTH: true
      CERTIFICATES_ENABLED: true
      DISABLE_LOGIN_BUTTON: false
      DISPLAY_HISTOGRAMS_TO_STAFF: true
      ENABLE_COURSE_BLOCKS_NAVIGATION_API: true
      ENABLE_DISCUSSION_SERVICE: true
      ENABLE_INSTRUCTOR_ANALYTICS: true
      ENABLE_INSTRUCTOR_LEGACY_DASHBOARD: true
      ENABLE_PEARSON_HACK_TEST: false
      ENABLE_RENDER_XBLOCK_API: true
      ENABLE_SPECIAL_EXAMS: true
      REROUTE_ACTIVATION_EMAIL: {{ DEFAULT_FEEDBACK_EMAIL }}
      SUBDOMAIN_BRANDING: false
      SUBDOMAIN_COURSE_LISTINGS: false
      PREVIEW_LMS_BASE: "preview.localhost:18020"

    common_env_config: &common_env_config
      ADDL_INSTALLED_APPS:
        - ubcpi
      ADMINS:
      - ['Devstack Stacktrace Recipients', {{ DEFAULT_FEEDBACK_EMAIL }}]
      SERVER_EMAIL: {{ DEFAULT_FEEDBACK_EMAIL }}
      TIME_ZONE_DISPLAYED_FOR_DEADLINES: "{{ TIME_ZONE }}"
      SITE_NAME: {{ HOST_IP }}

    EDXAPP_LMS_ENV_EXTRA:
      <<: *common_env_config
      BULK_EMAIL_DEFAULT_FROM_EMAIL: {{ DEFAULT_FEEDBACK_EMAIL }}
      EDXAPP_ANALYTICS_DASHBOARD_URL: !!null
      FEATURES:
        <<: *common_feature_flags
        ALLOW_COURSE_STAFF_GRADE_DOWNLOADS: true
        ENABLE_AUTO_COURSE_REGISTRATION: true
        ENABLE_INSTRUCTOR_EMAIL: true
        ENABLE_INSTRUCTOR_REMOTE_GRADEBOOK_CONTROLS: true
        ENABLE_PAID_COURSE_REGISTRATION: false
        ENABLE_PSYCHOMETRICS: false
        ENABLE_S3_GRADE_DOWNLOADS: true
        ENABLE_SHOPPING_CART: true
        ENABLE_SYSADMIN_DASHBOARD: true
        INDIVIDUAL_DUE_DATES: true
        LICENSING: true
        REQUIRE_COURSE_EMAIL_AUTH: false
        RESTRICT_ENROLL_NO_ATSIGN_USERNAMES: true
      GIT_IMPORT_STATIC: false
      LOGGING_ENV: {{ edxapp_log_env }}
      PLATFORM_NAME: "ODL Devstack"
      STUDENT_FILEUPLOAD_MAX_SIZE: 20 * 1024 * 1024

    EDXAPP_CMS_ENV_EXTRA:
      <<: *common_env_config
      FEATURES:
        <<: *common_feature_flags
        ALLOW_COURSE_RERUNS: false
        ALLOW_HIDING_DISCUSSION_TAB: true
        DISABLE_COURSE_CREATION: true
        DISABLE_START_DATES: true
        ENABLE_EXPORT_GIT: true
        ENABLE_PUSH_TO_LMS: true
        ENABLE_SQL_TRACKING_LOGS: true
        SEGMENT_IO: false
        STAFF_EMAIL: {{ DEFAULT_FEEDBACK_EMAIL }}
      LOGGING_ENV: {{ edxapp_log_env }}

    ################################################################################
    #################### Forum Settings ############################################
    ################################################################################

    FORUM_ELASTICSEARCH_HOST: "elasticsearch.service.consul"
    FORUM_MONGO_USER: {{ forum_mongodb_username }}
    FORUM_MONGO_PASSWORD: {{ forum_mongodb_password }}
    FORUM_MONGO_HOSTS:
      - {{ MONGODB_HOST }}
    FORUM_MONGO_PORT: {{ MONGODB_PORT }}
    FORUM_MONGO_DATABASE: forum_{{ purpose_suffix }}
    FORUM_RACK_ENV: "production"
    FORUM_SINATRA_ENV: "production"
    FORUM_USE_TCP: True
    forum_source_repo: "https://github.com/mitodl/cs_comments_service.git"
    forum_version: open-release/ginkgo.master

    EDXAPP_LMS_PREVIEW_NGINX_PORT: 80
    EDXAPP_LMS_NGINX_PORT: 80
    EDXAPP_LMS_SSL_NGINX_PORT: 443
    edx_platform_repo: 'https://github.com/mitodl/edx-platform.git'
    edx_platform_version: 'mitx/ginkgo'

    COMMON_ENABLE_AWS_ROLE: False
