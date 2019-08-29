{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set purpose_prefix = purpose.rsplit('-', 1)[0] %}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set cloudfront_domain = salt.sdb.get('sdb://consul/cloudfront/' ~ purpose_prefix ~ '-' ~ environment ~ '-cdn') %}
{% set purpose_data = env_data.purposes[purpose] %}
{% set bucket_prefix = env_data.secret_backends.aws.bucket_prefix %}
{% set bucket_uses = env_data.secret_backends.aws.bucket_uses %}

{% set DEFAULT_FEEDBACK_EMAIL = 'mitx-support@mit.edu' %}
{% set DEFAULT_FROM_EMAIL = 'mitx-support@mit.edu' %}
{% set LMS_DOMAIN = purpose_data.domains.lms %}
{% set CMS_DOMAIN = purpose_data.domains.cms %}
{% set EDXAPP_LMS_ISSUER = "https://{}/oauth2".format(LMS_DOMAIN) %}
{% set EDXAPP_CMS_ISSUER = "https://{}/oauth2".format(CMS_DOMAIN) %}
{% set TIME_ZONE = 'America/New_York' %}
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
{% if environment == 'mitx-qa' %}
{% set efs_id = 'fs-6f55af26' %}
{% elif environment == 'mitx-production' %}
{% set efs_id = 'fs-1f27ae56' %}
{% elif environment == 'mitxpro-qa' %}
{% set efs_id = 'fs-b3865653' %}
{% elif environment == 'mitxpro-production' %}
{% set efs_id = 'fs-68918b88' %}
{% endif %}
{% if environment == 'mitxpro-qa' %}
  {% set edxapp_google_analytics_account = 'UA-5145472-40' %}
  {% elif environment = 'mitxpro-production' %}
  {% set edxapp_google_analytics_account = 'UA-5145472-38' %}
{% endif %}
{% if 'live' in purpose %}
  {% set edxapp_git_repo_dir = '/mnt/data/prod_repos' %}
  {% set edxapp_course_about_visibility_permission = 'see_exists' %}
  {% set edxapp_course_catalog_visibility_permission = 'see_exists' %}
  {% set edxapp_course_default_invite_only = False %}
  {% set edxapp_aws_grades_root_path = 'rp-prod/grades' %}
  {% set edxapp_upload_storage_prefix = 'submissions_attachments_prod' %}
  {% set edxapp_log_env_suffix = 'prod' %}
{% elif 'draft' in purpose %}
  {% set edxapp_git_repo_dir = '/mnt/data/repos' %}
  {% set edxapp_course_about_visibility_permission = 'staff' %}
  {% set edxapp_course_catalog_visibility_permission = 'staff' %}
  {% set edxapp_course_default_invite_only = True %}
  {% set edxapp_aws_grades_root_path =  'rp-dev/grades' %}
  {% set edxapp_upload_storage_prefix = 'submissions_attachments_dev' %}
  {% set edxapp_log_env_suffix = 'dev' %}
{% else %}
  {% set edxapp_git_repo_dir = '/mnt/data/repos' %}
  {% set edxapp_course_about_visibility_permission = 'see_exists' %}
  {% set edxapp_course_catalog_visibility_permission = 'see_exists' %}
  {% set edxapp_course_default_invite_only = False %}
  {% set edxapp_aws_grades_root_path =  'grades' %}
  {% set edxapp_upload_storage_prefix = 'submissions_attachments' %}
  {% set edxapp_log_env_suffix = 'prod' %}
{% endif %}

edx:
  {% if 'edx-worker' in roles %}
  playbooks:
    - 'worker.yml'
  {% endif %}
  efs_id: {{ efs_id }}
  edxapp:
    GIT_REPO_DIR: {{ edxapp_git_repo_dir }}

  ansible_vars:
    ### EDXAPP ENVIRONMENT ###
    EDXAPP_LOGIN_REDIRECT_WHITELIST: {{ purpose_data.domains.values()|tojson }}
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
    XQUEUE_LOGGING_ENV: {{ edxapp_log_env_suffix }}
    XQUEUE_DJANGO_USERS:
      {{ edxapp_xqueue_creds.data.username }}: {{ edxapp_xqueue_creds.data.password }}
      {{ xqwatcher_xqueue_creds.data.username }}: {{ xqwatcher_xqueue_creds.data.password }}
    XQUEUE_AWS_ACCESS_KEY_ID: __vault__:cache:aws-mitx/creds/{{ bucket_prefix }}-s3-{{ purpose }}-{{ environment }}>data>access_key
    XQUEUE_AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/{{ bucket_prefix }}-s3-{{ purpose }}-{{ environment }}>data>secret_key
    XQUEUE_BASIC_AUTH_USER: mitx
    XQUEUE_BASIC_AUTH_PASSWORD: __vault__:gen_if_missing:secret-{{ business_unit }}/global/xqueue-password>data>value
    XQUEUE_MYSQL_DB_NAME: xqueue_{{ purpose_suffix }}
    XQUEUE_MYSQL_HOST: {{ MYSQL_HOST }}
    XQUEUE_MYSQL_PASSWORD: __vault__:cache:mysql-{{ environment }}/creds/xqueue-{{ purpose }}>data>password
    XQUEUE_MYSQL_PORT: {{ MYSQL_PORT }}
    XQUEUE_MYSQL_USER: __vault__:cache:mysql-{{ environment }}/creds/xqueue-{{ purpose }}>data>username
    XQUEUE_UPLOAD_BUCKET: {{ bucket_prefix }}-grades-{{ purpose }}-{{ environment }}
    xqueue_source_repo: {{ purpose_data.versions.xqueue_source_repo }}
    xqueue_version: {{ purpose_data.versions.xqueue }}
    ########## END XQUEUE ########################################


    ################################################################################
    #################### Forum Settings ############################################
    ################################################################################
    FORUM_API_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/global/forum-api-key>data>value
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
    {% if environment == 'mitx-production' or environment == 'mitxpro-production' %}
    COMMON_ENABLE_NEWRELIC: True
    COMMON_ENABLE_NEWRELIC_APP: True
    NEWRELIC_LICENSE_KEY: __vault__::secret-operations/global/newrelic-license-key>data>value
    {% endif %}

    EDXAPP_MYSQL_CSMH_DB_NAME: edxapp_csmh_{{ purpose_suffix }}
    EDXAPP_MYSQL_CSMH_HOST: {{ MYSQL_HOST }}
    EDXAPP_MYSQL_CSMH_PASSWORD: __vault__:cache:mysql-{{ environment }}/creds/edxapp-csmh-{{ purpose }}>data>password
    EDXAPP_MYSQL_CSMH_PORT: {{ MYSQL_PORT }}
    EDXAPP_MYSQL_CSMH_USER: __vault__:cache:mysql-{{ environment }}/creds/edxapp-csmh-{{ purpose }}>data>username

    EDXAPP_DEFAULT_FILE_STORAGE: 'storages.backends.s3boto.S3BotoStorage'
    EDXAPP_AWS_STORAGE_BUCKET_NAME: {{ bucket_prefix }}-storage-{{ purpose }}-{{ environment }}
    EDXAPP_IMPORT_EXPORT_BUCKET: {{ bucket_prefix }}-storage-{{ purpose }}-{{ environment }}
    edxapp_course_static_dir: /edx/var/edxapp/course_static_dummy {# private variable, used to hack around the fact that we mount our course data via a shared file system (tmacey 2017-03-16) #}
    {# residential only, set this in order to override the `fs_root` setting for module/content store, need to understand more fully how this gets used in GITHUB_REPO_ROOT (tmacey 2017/03/17) #}
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
    EDXAPP_BUGS_EMAIL: mitx-support@mit.edu
    EDXAPP_COMMENTS_SERVICE_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/global/forum-api-key>data>value
    EDXAPP_COMMENTS_SERVICE_URL: "http://localhost:4567"
    EDXAPP_LMS_ISSUER: "{{ EDXAPP_LMS_ISSUER }}"
    EDXAPP_CONTACT_EMAIL: mitx-support@mit.edu
    EDXAPP_DEFAULT_FEEDBACK_EMAIL: "{{ DEFAULT_FEEDBACK_EMAIL }}"
    EDXAPP_DEFAULT_FROM_EMAIL: "{{ DEFAULT_FROM_EMAIL }}"
    EDXAPP_EMAIL_HOST: __vault__::secret-operations/global/mit-smtp>data>relay_host
    EDXAPP_EMAIL_PORT: __vault__::secret-operations/global/mit-smtp>data>relay_port
    EDXAPP_EMAIL_HOST_USER: __vault__::secret-operations/global/mit-smtp>data>relay_username
    EDXAPP_EMAIL_HOST_PASSWORD: __vault__::secret-operations/global/mit-smtp>data>relay_password
    EDXAPP_EMAIL_USE_TLS: True
    EDXAPP_EMAIL_USE_DEFAULT_FROM_FOR_BULK: True
    EDXAPP_GRADE_BUCKET: {{ bucket_prefix }}-grades-{{ purpose }}-{{ environment }}
    EDXAPP_GRADE_ROOT_PATH: {{ edxapp_aws_grades_root_path }}
    EDXAPP_GRADE_STORAGE_TYPE: S3
    EDXAPP_GIT_REPO_DIR: "{{ edxapp_git_repo_dir }}"
    EDXAPP_PLATFORM_NAME: MITx Residential
    EDXAPP_PLATFORM_DESCRIPTION: 'MITx Residential Online Course Portal'

    EDXAPP_SEARCH_HOST: elasticsearch.service.consul
    {% if cloudfront_domain %}
    EDXAPP_STATIC_URL_BASE: "https://{{ cloudfront_domain }}/static/"
    {% else %}
    EDXAPP_STATIC_URL_BASE: /static/
    {% endif %}
    EDXAPP_TECH_SUPPORT_EMAIL: mitx-support@mit.edu
    EDXAPP_CMS_ISSUER: "{{ EDXAPP_CMS_ISSUER }}"
    EDXAPP_VIDEO_IMAGE_SETTINGS:
      VIDEO_IMAGE_MAX_BYTES : 2097152
      VIDEO_IMAGE_MIN_BYTES : 2048
      STORAGE_CLASS: 'storages.backends.s3boto.S3BotoStorage'
      STORAGE_KWARGS:
        bucket: {{ bucket_prefix }}-edx-video-upload-{{ purpose }}-{{ environment }}
      DIRECTORY_PREFIX: 'video-images/'
    EDXAPP_VIDEO_TRANSCRIPTS_SETTINGS:
      VIDEO_TRANSCRIPTS_MAX_BYTES : 3145728
      STORAGE_CLASS: 'storages.backends.s3boto.S3BotoStorage'
      STORAGE_KWARGS:
        bucket: {{ bucket_prefix }}-storage-{{ purpose }}-{{ environment }}
      DIRECTORY_PREFIX: 'video-transcripts/'

    common_feature_flags: &common_feature_flags
      COURSE_DEFAULT_INVITE_ONLY: {{ edxapp_course_default_invite_only }}
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
      DATA_DIR: {{ edxapp_git_repo_dir }}
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
        ENABLE_GRADE_DOWNLOADS: true
        ENABLE_SHOPPING_CART: true
        ENABLE_SYSADMIN_DASHBOARD: true
        ENABLE_INSTRUCTOR_EMAIL: true
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
    EDXAPP_FILE_UPLOAD_STORAGE_BUCKET_NAME: {{ bucket_prefix }}-storage-{{ purpose }}-{{ environment }}
    EDXAPP_FILE_UPLOAD_STORAGE_PREFIX: "{{ edxapp_upload_storage_prefix }}"
    OAUTH_OIDC_ISSUER: "{{ EDXAPP_CMS_ISSUER }}"
    LOGGING_ENV: cms-{{ edxapp_log_env_suffix }}
    EDXAPP_XQUEUE_DJANGO_AUTH:
      username: {{ edxapp_xqueue_creds.data.username }}
      password: {{ edxapp_xqueue_creds.data.password }}
