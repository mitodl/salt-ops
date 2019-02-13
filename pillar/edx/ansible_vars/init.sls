#!jinja|yaml|gpg

{# EDXAPP_LMS_SITE_NAME: lms.service.consul #}
{# EDXAPP_CMS_SITE_NAME: cms.service.consul #}

{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set purpose_data = env_settings.environments[environment].purposes[purpose] %}

{% set CMS_DOMAIN = purpose_data.domains.cms %}
{% set EDXAPP_CMS_ISSUER = "https://{}/oauth2".format(CMS_DOMAIN) %}
{# multivariate #}
{% set LMS_DOMAIN = purpose_data.domains.lms %}
{% set EDXAPP_LMS_ISSUER = "https://{}/oauth2".format(LMS_DOMAIN) %}
{% set MONGODB_HOST = 'mongodb-master.service.consul' %}
{% set MONGODB_MODULESTORE_ENGINE =  'xmodule.modulestore.mongo.MongoModuleStore' %}
{% set MONGODB_REPLICASET = salt.pillar.get('mongodb:replset_name', 'rs0') %}
{% set MONGODB_PORT = 27017 %}
{% set MONGODB_USE_SSL = False %}
{% set MYSQL_HOST = 'mysql.service.consul' %}
{% set MYSQL_PORT = 3306 %}

{% set TIME_ZONE = 'America/New_York' %}
{% set TLS_LOCATION = '/etc/pki/tls/certs' %}
{% set TLS_KEY_NAME = 'edx-ssl-cert' %}

{% set XQUEUE_USER = 'lms' %}

edx:
  ansible_vars:
    ### COMMON VARS ###
    COMMON_MYSQL_ADMIN_USER: __vault__:cache:mysql-{{ environment }}/creds/admin>data>username
    COMMON_MYSQL_ADMIN_PASS: __vault__:cache:mysql-{{ environment }}/creds/admin>data>password
    COMMON_MYSQL_MIGRATE_USER: __vault__:cache:mysql-{{ environment }}/creds/admin>data>username
    COMMON_MYSQL_MIGRATE_PASS: __vault__:cache:mysql-{{ environment }}/creds/admin>data>password

    ### EDXAPP ENVIRONMENT ###
    {# TODO: Determine if this is still necessary (tmacey 2017/03/16) #}
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
    elb_pre_post: false {# prevents ansible from trying to handle ELB for us (tmacey 2017-03-16) #}
    EDXAPP_AWS_S3_CUSTOM_DOMAIN: !!null
    EDXAPP_CMS_ROOT_URL: "https://{{ CMS_DOMAIN }}"
    {# Tell Ansible to install python dependencies from github. https://github.com/edx/edx-platform/blob/ned%2Ftest-ficus/requirements/edx/edx-private.txt#L1 (tmacey 2017/03/16) #}
    EDXAPP_EDXAPP_SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/edxapp-django-secret-key>data>value
    EDXAPP_INSTALL_PRIVATE_REQUIREMENTS: true
    EDXAPP_LMS_ROOT_URL: "https://{{ LMS_DOMAIN }}"
    EDXAPP_LMS_SITE_NAME: {{ purpose_data.domains.lms }}
    EDXAPP_CMS_SITE_NAME: {{ purpose_data.domains.cms }}

    ####################################################################
    ############### MongoDB SETTINGS ###################################
    ####################################################################
    {# Settings for Content Store #}
    EDXAPP_MONGO_DB_NAME: contentstore_{{ purpose_suffix }}
    EDXAPP_MONGO_HOSTS: {{ MONGODB_HOST }}
    EDXAPP_MONGO_PASSWORD: __vault__:cache:mongodb-{{ environment }}/creds/contentstore-{{ purpose }}>data>password
    EDXAPP_MONGO_PORTS: {{ MONGODB_PORT }}
    EDXAPP_MONGO_REPLICA_SET: rs0
    EDXAPP_MONGO_USER: __vault__:cache:mongodb-{{ environment }}/creds/contentstore-{{ purpose }}>data>username
    {# TODO: revisit once PKI is deployed (tmacey 2017/03/17) #}
    EDXAPP_MONGO_USE_SSL: {{ MONGODB_USE_SSL }}
    EDXAPP_CONTENTSTORE_ADDITIONAL_OPTS:
      default:
        db: contentstore_{{ purpose_suffix }}
        password: __vault__:cache:mongodb-{{ environment }}/creds/contentstore-{{ purpose }}>data>password
        user: __vault__:cache:mongodb-{{ environment }}/creds/contentstore-{{ purpose }}>data>username

    {# Settings for Module Store #}
    {# We have to replicate the data three times in order to allow for #}
    {# a different database name between the content and module stores. #}
    {# It is a quirk of how the edX Ansible repo has the vars configured. #}
    {# (tmacey 2017/03/17) #}
    EDXAPP_LMS_DRAFT_DOC_STORE_CONFIG:
      db: modulestore_{{ purpose_suffix }}
      host: "{{ MONGODB_HOST }}"
      {# multivariate, vault #}
      password: __vault__:cache:mongodb-{{ environment }}/creds/modulestore-{{ purpose }}>data>password
      port: {{ MONGODB_PORT }}
      {# multivariate, vault #}
      user: __vault__:cache:mongodb-{{ environment }}/creds/modulestore-{{ purpose }}>data>username
      collection: 'modulestore'
      replicaset: "{{ MONGODB_REPLICASET }}"
      readPreference: "nearest"
      ssl: {{ MONGODB_USE_SSL }}
      socketTimeoutMS: 3000
      connectTimeoutMS: 2000

    EDXAPP_LMS_SPLIT_DOC_STORE_CONFIG:
      db: modulestore_{{ purpose_suffix }}
      host: "{{ MONGODB_HOST }}"
      {# multivariate, vault #}
      password: __vault__:cache:mongodb-{{ environment }}/creds/modulestore-{{ purpose }}>data>password
      port: {{ MONGODB_PORT }}
      {# multivariate, vault #}
      user: __vault__:cache:mongodb-{{ environment }}/creds/modulestore-{{ purpose }}>data>username
      collection: 'modulestore'
      replicaset: "{{ MONGODB_REPLICASET }}"
      readPreference: "nearest"
      ssl: {{ MONGODB_USE_SSL }}
      socketTimeoutMS: 3000
      connectTimeoutMS: 2000

    EDXAPP_CMS_DOC_STORE_CONFIG:
      db: modulestore_{{ purpose_suffix }}
      host: "{{ MONGODB_HOST }}"
      {# multivariate, vault #}
      password: __vault__:cache:mongodb-{{ environment }}/creds/modulestore-{{ purpose }}>data>password
      port: {{ MONGODB_PORT }}
      {# multivariate, vault #}
      user: __vault__:cache:mongodb-{{ environment }}/creds/modulestore-{{ purpose }}>data>username
      collection: 'modulestore'
      replicaset: "{{ MONGODB_REPLICASET }}"
      readPreference: "nearest"
      ssl: {{ MONGODB_USE_SSL }}
      socketTimeoutMS: 3000
      connectTimeoutMS: 2000


    #####################################################################
    ############### MySQL Config ########################################
    #####################################################################
    EDXAPP_MYSQL_DB_NAME: edxapp_{{ purpose_suffix }}
    EDXAPP_MYSQL_HOST: {{ MYSQL_HOST }}
    EDXAPP_MYSQL_PASSWORD: __vault__:cache:mysql-{{ environment }}/creds/edxapp-{{ purpose }}>data>password
    EDXAPP_MYSQL_PORT: {{ MYSQL_PORT }}
    EDXAPP_MYSQL_USER: __vault__:cache:mysql-{{ environment }}/creds/edxapp-{{ purpose }}>data>username

    #####################################################################
    ########### Auth Configs ############################################
    #####################################################################
    EDXAPP_AWS_ACCESS_KEY_ID: __vault__:cache:aws-mitx/creds/mitx-s3-{{ purpose }}-{{ environment }}>data>access_key
    EDXAPP_AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/mitx-s3-{{ purpose }}-{{ environment }}>data>secret_key
    EDXAPP_CELERY_BROKER_HOSTNAME: nearest-rabbitmq.query.consul
    EDXAPP_CELERY_BROKER_TRANSPORT: 'amqp'
    EDXAPP_CELERY_PASSWORD: __vault__:cache:rabbitmq-{{ environment }}/creds/celery-{{ purpose }}>data>password
    EDXAPP_CELERY_USER: __vault__:cache:rabbitmq-{{ environment }}/creds/celery-{{ purpose }}>data>username
    EDXAPP_LMS_AUTH_EXTRA:
      MONGODB_LOG:
        db: gitlog_{{ purpose_suffix }}
        host: mongodb-master.service.consul
        user: __vault__:cache:mongodb-{{ environment }}/creds/gitlog-{{ purpose }}>data>username
        password: __vault__:cache:mongodb-{{ environment }}/creds/gitlog-{{ purpose }}>data>password
        replicaset: "{{ MONGODB_REPLICASET }}"
        readPreference: "nearest"

    #####################################################################
    ########### Environment Configs #####################################
    #####################################################################

    EDXAPP_ANALYTICS_DASHBOARD_URL: !!null
    {# multivariate #}
    EDXAPP_CELERY_BROKER_VHOST: /celery_{{ purpose_suffix }}
    EDXAPP_CMS_BASE: {{ CMS_DOMAIN }}
    EDXAPP_CMS_MAX_REQ: 1000
    EDXAPP_ENABLE_CSMH_EXTENDED: False
    EDXAPP_ENABLE_READING_FROM_MULTIPLE_HISTORY_TABLES: False
    EDXAPP_CUSTOM_COURSES_EDX: True
    EDXAPP_ELASTIC_SEARCH_CONFIG:
      - host: nearest-elasticsearch.query.consul
        port: 9200
    {# multivariate #}
    EDXAPP_ENABLE_OAUTH2_PROVIDER: False
    {# multivariate #}
    EDXAPP_JWT_SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/edxapp-jwt-secret-key>data>value
    EDXAPP_LMS_BASE: "{{ LMS_DOMAIN }}"
    EDXAPP_LMS_MAX_REQ: 1000
    EDXAPP_MKTG_URL_LINK_MAP:
      CONTACT: !!null
      FAQ: !!null
      HONOR: !!null
      PRIVACY: !!null
    EDXAPP_ORA2_FILE_PREFIX: "{{ salt.grains.get('environment') }}-dev/ora2"
    EDXAPP_RABBIT_HOSTNAME: nearest-rabbitmq.query.consul
    EDXAPP_TIME_ZONE: "{{ TIME_ZONE }}"

    # Use YAML references (& and *) and hash merge <<: to factor out shared settings
    # see http://atechie.net/2009/07/merging-hashes-in-yaml-conf-files/
    common_feature_flags: &common_feature_flags
      ALLOW_ALL_ADVANCED_COMPONENTS: true
      AUTH_USE_CERTIFICATES: false
      AUTH_USE_OPENID_PROVIDER: false
      BYPASS_ACTIVATION_EMAIL_FOR_EXTAUTH: true
      CERTIFICATES_ENABLED: false
      DISABLE_LOGIN_BUTTON: false
      DISPLAY_HISTOGRAMS_TO_STAFF: true
      ENABLE_COURSE_BLOCKS_NAVIGATION_API: true
      ENABLE_DISCUSSION_SERVICE: true
      ENABLE_PEARSON_HACK_TEST: false
      ENABLE_RENDER_XBLOCK_API: true
      ENABLE_SPECIAL_EXAMS: true
      PREVIEW_LMS_BASE: {{ purpose_data.domains.preview }}
      RESTRICT_ENROLL_BY_REG_METHOD: false
      SUBDOMAIN_BRANDING: false
      SUBDOMAIN_COURSE_LISTINGS: false
      MILESTONES_APP: true
      ENABLE_PREREQUISITE_COURSES: true

    EDXAPP_LMS_ENV_EXTRA:
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
      FEATURES:
        <<: *common_feature_flags
        ALLOW_PUBLIC_ACCOUNT_CREATION: false
        ENABLE_AUTO_COURSE_REGISTRATION: true
        ENABLE_PAID_COURSE_REGISTRATION: false
        ENABLE_UNICODE_USERNAME: true
        INDIVIDUAL_DUE_DATES: true
        LICENSING: true
        REQUIRE_COURSE_EMAIL_AUTH: false
        RESTRICT_ENROLL_NO_ATSIGN_USERNAMES: true
      FIELD_OVERRIDE_PROVIDERS:
        - courseware.student_field_overrides.IndividualStudentOverrideProvider
      GIT_IMPORT_STATIC: True
      OAUTH_OIDC_ISSUER: "{{ EDXAPP_LMS_ISSUER }}"

    EDXAPP_CMS_ENV_EXTRA:
      FEATURES:
        <<: *common_feature_flags
        ALLOW_COURSE_RERUNS: true
        ALLOW_HIDING_DISCUSSION_TAB: true
        ALLOW_PUBLIC_ACCOUNT_CREATION: False
        DISABLE_COURSE_CREATION: true
        DISABLE_START_DATES: true
        SEGMENT_IO: false
      OAUTH_OIDC_ISSUER: "{{ EDXAPP_CMS_ISSUER }}"

    ### Specific configuration overrides ###

    {# multivariate #}
    edx_platform_version: {{ purpose_data.versions.edxapp }}
    edx_platform_repo: {{ purpose_data.versions.edx_platform_repo }}

    EDXAPP_LMS_PREVIEW_NGINX_PORT: 80
    EDXAPP_CMS_NGINX_PORT: 80
    EDXAPP_LMS_NGINX_PORT: 80
    EDXAPP_CMS_SSL_NGINX_PORT: 443
    EDXAPP_LMS_SSL_NGINX_PORT: 443

    # Configure TLS
    NGINX_ENABLE_SSL: True
    NGINX_REDIRECT_TO_HTTPS: True
    NGINX_HTTPS_REDIRECT_STRATEGY: forward_for_proto

    NGINX_SSL_CERTIFICATE: '{{ TLS_LOCATION }}/{{ TLS_KEY_NAME }}.crt'
    NGINX_SSL_KEY: '{{ TLS_LOCATION }}/{{ TLS_KEY_NAME }}.key'

    # Specify nginx log format
    NGINX_LOG_FORMAT_NAME: 'app_metrics'

    # Configure HTTP auth
    COMMON_ENABLE_BASIC_AUTH: False

    # Ask search bots to not index sandboxes
    NGINX_ROBOT_RULES:
      - agent: '*'
        disallow: '/'

    # Disable useless roles
    COMMON_ENABLE_AWS_ROLE: False
    COMMON_ENABLE_NEWRELIC: False
    COMMON_ENABLE_NEWRELIC_INFRASTRUCTURE: False
    COMMON_ENABLE_MINOS: False
