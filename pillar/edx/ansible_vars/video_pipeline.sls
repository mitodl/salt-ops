{% set env_settings = salt.cp.get_file_str("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml")|load_yaml %}
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
{% set cache_configs = env_settings.environments[environment].backends.elasticache %}

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
      BUCKET: {{ bucket_prefix }}-edx-video-upload-{{ environment }}
      ROOT_PATH: "ingest/"

    VIDEO_PIPELINE_BASE_AWS_VIDEO_IMAGES:
      BUCKET: {{ bucket_prefix }}-edx-video-upload-{{ environment }}
      ROOT_PATH: "video-images/"

    VIDEO_PIPELINE_BASE_AWS_VIDEO_TRANSCRIPTS:
      BUCKET: {{ bucket_prefix }}-edx-video-upload-{{ environment }}
      ROOT_PATH: "video-transcripts/"

    VIDEO_PIPELINE_BASE_EDX_CLOUDFRONT_PREFIX: https://{{ cloudfront_domain }}
    VIDEO_PIPELINE_BASE_EDX_S3_ENDPOINT_BUCKET: {{ bucket_prefix }}-edx-video-delivery-{{ environment }}
    VIDEO_PIPELINE_BASE_VEDA_S3_UPLOAD_BUCKET: {{ bucket_prefix }}-veda-upload-{{ purpose }}-{{ environment }}
    VIDEO_PIPELINE_BASE_VEDA_S3_HOTSTORE_BUCKET: {{ bucket_prefix }}-veda-hotstore-{{ purpose }}-{{ environment }}
    VIDEO_PIPELINE_BASE_VEDA_DELIVERABLE_BUCKET: {{ bucket_prefix }}-veda-deliverable-{{ purpose }}-{{ environment }}

    VIDEO_PIPELINE_BASE_VEDA_ACCESS_KEY_ID: __vault__:cache:aws-mitx/creds/{{ bucket_prefix }}-s3-xpro-qa-{{ environment }}>data>access_key
    VIDEO_PIPELINE_BASE_VEDA_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/{{ bucket_prefix }}-s3-xpro-qa-{{ environment }}>data>access_key

    VIDEO_PIPELINE_BASE_ADMIN_EMAIL: mitx-support@mit.edu
    VIDEO_PIPELINE_BASE_VEDA_NOREPLY_EMAIL: "mitx-noreply@mit.edu"

    VIDEO_PIPELINE_BASE_CIELO24_API_ENVIRONMENT: {{ environment }}
    VIDEO_PIPELINE_BASE_TRANSCRIPT_PROVIDER_REQUEST_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/video-{{ purpose }}-transcript-request-token>data>value

    VIDEO_PIPELINE_BASE_SOCIAL_AUTH_EDX_OIDC_KEY: {{ bucket_prefix }}-{{ environment }}-oidc-key
    VIDEO_PIPELINE_BASE_SOCIAL_AUTH_EDX_OIDC_SECRET: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/edx-open-id-connect-secret>data>value

    VIDEO_PIPELINE_BASE_VAL_USERNAME: "staff"
    VIDEO_PIPELINE_BASE_VAL_PASSWORD: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/edx-video-val-password>data>value

    VIDEO_PIPELINE_BASE_SG_SERVER_PATH: "SET-ME-PLEASE"
    VIDEO_PIPELINE_BASE_SG_SCRIPT_NAME: "SET-ME-PLEASE"
    VIDEO_PIPELINE_BASE_SG_SCRIPT_KEY: "SET-ME-PLEASE"

    VIDEO_PIPELINE_BASE_HOST_ENVIRONMENT: {{ environment }}

    ##################################################################
    #################### Video Web UI ################################
    ##################################################################
    VEDA_WEB_FRONTEND_MEMCACHE:
      {% for cache_config in cache_configs %}
      {% set cache_purpose = cache_config.get('purpose', 'shared') %}
      {% if cache_purpose in purpose %}
      {% set ELASTICACHE_CONFIG = salt.boto3_elasticache.describe_cache_clusters(cache_config.cluster_id[:20].strip('-'), ShowCacheNodeInfo=True)[0] %}
      {% for host in ELASTICACHE_CONFIG.CacheNodes %}
      - {{ host.Endpoint.Address }}:{{ host.Endpoint.Port }}
      {% endfor %}
      {% endif %}
      {% endfor %}

    VEDA_WEB_FRONTEND_DJANGO_SETTINGS_MODULE: "VEDA.settings.production"

    VEDA_WEB_FRONTEND_SOCIAL_AUTH_REDIRECT_IS_HTTPS: true

    VEDA_WEB_FRONTEND_MEDIA_URL: "/media/"

    VEDA_WEB_FRONTEND_MEDIA_STORAGE_BACKEND:
      DEFAULT_FILE_STORAGE: "django.core.files.storage.FileSystemStorage"

    VEDA_WEB_FRONTEND_STATICFILES_STORAGE: "django.contrib.staticfiles.storage.StaticFilesStorage"
