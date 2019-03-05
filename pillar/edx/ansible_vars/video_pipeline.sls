{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set roles = salt.grains.get('roles', 'video-pipeline') %}
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

edx:
  playbooks:
    {% if 'video-worker' in roles %}
    - veda_delivery_worker.yml
    - veda_encode_worker.yml
    - veda_intake_worker.yml
    - veda_pipeline_worker.yml
    {% elif 'video-pipeline' in roles %}
    - veda_web_frontend.yml
    {% endif %}
  ansible_vars:
    ##################################################################
    #################### Video Pipeline Base #########################
    ##################################################################
    VIDEO_PIPELINE_BASE_OAUTH_CLIENT_ID: "video-pipeline-client-id"
    VIDEO_PIPELINE_BASE_OAUTH_CLIENT_NAME: "video-pipeline"
    VIDEO_PIPELINE_BASE_OAUTH_CLIENT_SECRET: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/video-pipeline-oauth-secret-key>data>value

    VIDEO_PIPELINE_BASE_SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/video-pipeline-django-secret-key>data>value

    VIDEO_PIPELINE_BASE_DEFAULT_DB_NAME: video-{{ purpose }}
    VIDEO_PIPELINE_BASE_MYSQL_HOST: mysql.service.consul
    VIDEO_PIPELINE_BASE_MYSQL_USER: __vault__:cache:mysql-{{ environment }}/creds/video-{{ purpose }}>data>username
    VIDEO_PIPELINE_BASE_MYSQL_PASSWORD: __vault__:cache:mysql-{{ environment }}/creds/video-{{ purpose }}>data>password

    VIDEO_PIPELINE_BASE_RABBITMQ_BROKER: nearest-rabbitmq.query.consul
    VIDEO_PIPELINE_BASE_RABBITMQ_USER: __vault__:cache:rabbitmq-{{ environment }}/creds/video-{{ purpose }}>data>username
    VIDEO_PIPELINE_BASE_RABBITMQ_PASS: __vault__:cache:rabbitmq-{{ environment }}/creds/video-{{ purpose }}>data>password

    # video pipeline config overrides

    VIDEO_PIPELINE_BASE_EDX_S3_INGEST:
      BUCKET: {{ bucket_prefix }}-edx-video-{{ environment }}
      ROOT_PATH: "ingest/"

    VIDEO_PIPELINE_BASE_AWS_VIDEO_IMAGES:
      BUCKET: {{ bucket_prefix }}-edx-video-{{ environment }}
      ROOT_PATH: "video-images/"

    VIDEO_PIPELINE_BASE_AWS_VIDEO_TRANSCRIPTS:
      BUCKET: {{ bucket_prefix }}-edx-video-{{ environment }}
      ROOT_PATH: "video-transcripts/"

    VIDEO_PIPELINE_BASE_EDX_CLOUDFRONT_PREFIX: https://{{ cloudfront_domain }}
    VIDEO_PIPELINE_BASE_EDX_S3_ENDPOINT_BUCKET: {{ bucket_prefix }}-edx-video-delivery-{{ environment }}
    VIDEO_PIPELINE_BASE_VEDA_S3_UPLOAD_BUCKET: {{ bucket_prefix }}-veda-upload-{{ purpose }}-{{ environment }}
    VIDEO_PIPELINE_BASE_VEDA_S3_HOTSTORE_BUCKET: {{ bucket_prefix }}-veda-hotstore-{{ purpose }}-{{ environment }}
    VIDEO_PIPELINE_BASE_VEDA_DELIVERABLE_BUCKET: {{ bucket_prefix }}-veda-deliverable-{{ purpose }}-{{ environment }}

    VIDEO_PIPELINE_BASE_VEDA_BASE_URL: "{{ VIDEO_PIPELINE_BASE_URL_ROOT }}"
    VIDEO_PIPELINE_BASE_VEDA_ACCESS_KEY_ID: __vault__:cache:aws-mitx/creds/video-{{ purpose }}-read-write-delete>data>access_key
    VIDEO_PIPELINE_BASE_VEDA_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/video-{{ purpose }}-read-write-delete>data>secret_key

    VIDEO_PIPELINE_BASE_ADMIN_EMAIL: mitx-support@mit.edu
    VIDEO_PIPELINE_BASE_VEDA_NOREPLY_EMAIL: "mitx-noreply@mit.edu"

    VIDEO_PIPELINE_BASE_CIELO24_API_ENVIRONMENT: {{ environment }}
    VIDEO_PIPELINE_BASE_TRANSCRIPT_PROVIDER_REQUEST_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/video-{{ purpose }}-transcript-request-token>data>value

    VIDEO_PIPELINE_BASE_SOCIAL_AUTH_EDX_OIDC_KEY: "pipeline-key"
    VIDEO_PIPELINE_BASE_SOCIAL_AUTH_EDX_OIDC_SECRET: "pipeline-secret"

    VIDEO_PIPELINE_BASE_VAL_CLIENT_ID: "{{ VIDEO_PIPELINE_BASE_SOCIAL_AUTH_EDX_OIDC_KEY }}"
    VIDEO_PIPELINE_BASE_VAL_SECRET_KEY: "{{ VIDEO_PIPELINE_BASE_SOCIAL_AUTH_EDX_OIDC_SECRET }}"
    VIDEO_PIPELINE_BASE_VAL_USERNAME: "staff"
    VIDEO_PIPELINE_BASE_VAL_PASSWORD: "edx"

    VIDEO_PIPELINE_BASE_SG_SERVER_PATH: "SET-ME-PLEASE"
    VIDEO_PIPELINE_BASE_SG_SCRIPT_NAME: "SET-ME-PLEASE"
    VIDEO_PIPELINE_BASE_SG_SCRIPT_KEY: "SET-ME-PLEASE"

    VIDEO_PIPELINE_BASE_HOST_ENVIRONMENT: {{ environment }}

    ##################################################################
    #################### Video Web UI ################################
    ##################################################################
    VEDA_WEB_FRONTEND_MEMCACHE: []

    VEDA_WEB_FRONTEND_DJANGO_SETTINGS_MODULE: "VEDA.settings.production"

    VEDA_WEB_FRONTEND_SOCIAL_AUTH_REDIRECT_IS_HTTPS: true

    VEDA_WEB_FRONTEND_DATA_DIR: "{{ COMMON_DATA_DIR }}/{{ veda_web_frontend_service_name }}"
    VEDA_WEB_FRONTEND_MEDIA_ROOT: "{{ VEDA_WEB_FRONTEND_DATA_DIR }}/media"
    VEDA_WEB_FRONTEND_MEDIA_URL: "/media/"

    VEDA_WEB_FRONTEND_MEDIA_STORAGE_BACKEND:
      DEFAULT_FILE_STORAGE: "django.core.files.storage.FileSystemStorage"
      MEDIA_ROOT: "{{ VEDA_WEB_FRONTEND_MEDIA_ROOT }}"
      MEDIA_URL: "{{ VEDA_WEB_FRONTEND_MEDIA_URL }}"

    VEDA_WEB_FRONTEND_ENVIRONMENT:
      VIDEO_PIPELINE_CFG: "{{ COMMON_CFG_DIR }}/{{ veda_web_frontend_service_name }}.yml"
      PYTHONPATH: "{{ veda_web_frontend_code_dir }}"

    VEDA_WEB_FRONTEND_STATICFILES_STORAGE: "django.contrib.staticfiles.storage.StaticFilesStorage"

    VEDA_WEB_FRONTEND_SERVICE_CONFIG: !!null
    VEDA_WEB_FRONTEND_SECRET_KEY: '{{ VIDEO_PIPELINE_BASE_SECRET_KEY }}'

    VEDA_WEB_FRONTEND_GUNICORN_PORT: '{{ VIDEO_PIPELINE_BASE_GUNICORN_PORT }}'
    VEDA_WEB_FRONTEND_NGINX_PORT: '{{ VIDEO_PIPELINE_BASE_NGINX_PORT }}'
    VEDA_WEB_FRONTEND_SSL_NGINX_PORT: '{{ VIDEO_PIPELINE_BASE_SSL_NGINX_PORT }}'

    VEDA_WEB_FRONTEND_DEFAULT_DB_NAME: '{{ VIDEO_PIPELINE_BASE_DEFAULT_DB_NAME }}'
    VEDA_WEB_FRONTEND_MYSQL_HOST: '{{ VIDEO_PIPELINE_BASE_MYSQL_HOST }}'
    VEDA_WEB_FRONTEND_MYSQL_USER: '{{ VIDEO_PIPELINE_BASE_MYSQL_USER }}'
    VEDA_WEB_FRONTEND_MYSQL_PASSWORD: '{{ VIDEO_PIPELINE_BASE_MYSQL_PASSWORD }}'

    VEDA_WEB_FRONTEND_OAUTH2_URL: '{{ VIDEO_PIPELINE_BASE_URL_ROOT }}/api/val/v0'
    VEDA_WEB_FRONTEND_LOGOUT_URL: '{{ VIDEO_PIPELINE_BASE_URL_ROOT }}/logout/'
    VEDA_WEB_FRONTEND_SOCIAL_AUTH_EDX_OIDC_KEY: '{{ VIDEO_PIPELINE_BASE_SOCIAL_AUTH_EDX_OIDC_KEY | default("pipeline-key") }}'
    VEDA_WEB_FRONTEND_SOCIAL_AUTH_EDX_OIDC_SECRET: '{{ VIDEO_PIPELINE_BASE_SOCIAL_AUTH_EDX_OIDC_SECRET | default("pipeline-secret") }}'
