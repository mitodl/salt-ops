{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}

{% set env_dict = {
    'rc': {
      'app_log_level': 'INFO',
      'app_name': 'mitopen-rc',
      'CELERY_WORKER_MAX_MEMORY_PER_CHILD': 125000,      
      'CORS_URLS': ['https://ocwnext-rc.odl.mit.edu', 'https://ocw-next.netlify.app', 'https://ol-devops-ci.odl.mit.edu', 'https://draft-qa.ocw.mit.edu', 'https://live-qa.ocw.mit.edu'],
      'DEBUG': False,
      'EDX_LEARNING_COURSE_BUCKET_NAME': 'edxorg-qa-edxapp-courses',
      'ENABLE_INFINITE_CORRIDOR': True,
      'env_name': 'rc',
      'GA_G_TRACKING_ID': '',
      'GA_TRACKING_ID': '',
      'INDEXING_API_USERNAME': 'od_mm_rc_api', 
      'NEW_RELIC_APP_NAME': 'mitopen-rc',
      'MAILGUN_SENDER_DOMAIN': 'discussions-mail.odl.mit.edu',
      'MITXPRO_BASE_URL': 'xpro-rc.odl.mit.edu',
      'OCW_ITERATOR_CHUNK_SIZE': 300,
      'OCW_NEXT_AWS_STORAGE_BUCKET_NAME': 'ol-ocw-studio-app-qa',
      'OCW_NEXT_BASE_URL': 'https://live-qa.ocw.mit.edu/',
      'OCW_NEXT_LIVE_BUCKET': 'ocw-content-live-qa',
      'OCW_UPLOAD_IMAGE_ONLY': True,
      'MITOPEN_BASE_URL': 'https://mit-open-rc.odl.mit.edu',
      'MITOPEN_COOKIE_NAME': 'mitopen-rc',
      'MITOPEN_COOKIE_DOMAIN': 'odl.mit.edu',
      'MITOPEN_SUPPORT_EMAIL': 'odl-mitopen-rc-support@mit.edu',
      'OPENSEARCH_INDEX': 'mitopen-rc',
      'OPENSEARCH_SHARD_COUNT': 2,
      'OPENSEARCH_URL': 'https://search-opensearch-open-qa-76e2mth7e5hvtclhuhh7uckoiu.us-east-1.es.amazonaws.com',
      'PGBOUNCER_DEFAULT_POOL_SIZE': 50,
      'PGBOUNCER_MAX_CLIENT_CONN': 500,
      'PGBOUNCER_MIN_POOL_SIZE': 20,
      'release_branch': 'md/ol-inf_issue-1657',
      'SSO_URL': 'sso-qa.odl.mit.edu',
      'TIKA_SERVER_ENDPOINT': 'https://tika-qa.odl.mit.edu',
      'env_stage': 'qa',
      },
    'production': {
      'app_log_level': 'INFO',
      'app_name': 'mitopen-production',
      'CELERY_WORKER_MAX_MEMORY_PER_CHILD': 250000,
      'CLOUDFRONT_DIST': 'd2mcnjhkvrfuy2',
      'CORS_URLS': ['https://ocw-preview.odl.mit.edu', "https://draft.ocw.mit.edu", "https://www.ocw.mit.edu", "https://ocw.mit.edu", 'https://live.ocw.mit.edu'],
      'DEBUG': False,
      'EDX_LEARNING_COURSE_BUCKET_NAME': 'edxorg-production-edxapp-courses',
      'ENABLE_INFINITE_CORRIDOR': True,
      'env_name': 'production',
      'GA_G_TRACKING_ID': '',
      'GA_TRACKING_ID': '',
      'INDEXING_API_USERNAME': 'od_mm_prod_api',
      'NEW_RELIC_APP_NAME': 'mitopen-production',
      'MAILGUN_SENDER_DOMAIN': 'mail.open.mit.edu',
      'MICROMASTERS_BASE_URL': 'micromasters.mit.edu',
      'MITXPRO_BASE_URL': 'xpro.mit.edu',
      'OCW_ITERATOR_CHUNK_SIZE': 300,
      'OCW_NEXT_AWS_STORAGE_BUCKET_NAME': 'ol-ocw-studio-app-production',
      'OCW_NEXT_BASE_URL': 'https://ocw.mit.edu/',
      'OCW_NEXT_LIVE_BUCKET': 'ocw-content-live-production',
      'OCW_UPLOAD_IMAGE_ONLY': False,
      'MITOPEN_COOKIE_NAME': 'mitopenprod',
      'MITOPEN_BASE_URL': 'https://open.mit.edu',
      'MITOPEN_COOKIE_DOMAIN': 'mit.edu',
      'MITOPEN_SUPPORT_EMAIL': 'mitopen-support@mit.edu',
      'OPENSEARCH_INDEX': 'mitopen',
      'OPENSEARCH_SHARD_COUNT': 3,
      'OPENSEARCH_URL': 'https://search-opensearch-open-production-dg3wjt3eud45psxdrw3lz3k2ie.us-east-1.es.amazonaws.com',
      'PGBOUNCER_DEFAULT_POOL_SIZE': 50,
      'PGBOUNCER_MAX_CLIENT_CONN': 500,
      'PGBOUNCER_MIN_POOL_SIZE': 20,
      'release_branch': 'release',
      'SSO_URL': 'sso-production.odl.mit.edu',
      'TIKA_SERVER_ENDPOINT': 'https://tika-production.odl.mit.edu',
      'env_stage': 'production',
      }
} %}
{% set env_data = env_dict[environment] %}
{% set pg_creds = salt.vault.cached_read('postgres-mitopen/creds/app', cache_prefix='heroku-mitopen') %}

{% set etl_micromasters_host = salt.sdb.get('sdb://consul/open-{}-etl-micromasters-host'.format(environment)) %}
{% set etl_xpro_host = salt.sdb.get('sdb://consul/open-{}-etl-xpro-host'.format(environment)) %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/global/heroku/odl-devops-api-key>data>value
  config_vars:
    ALLOWED_HOSTS: '["*"]'
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/ol-mitopen-application>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/ol-mitopen-application>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'ol-mitopen-app-storage-{{ env_data.env_name }}'
    CELERY_WORKER_MAX_MEMORY_PER_CHILD: {{ env_data.CELERY_WORKER_MAX_MEMORY_PER_CHILD }}
    CKEDITOR_ENVIRONMENT_ID:  __vault__::secret-mitopen/data/secrets>data>data>ckeditor>environment_id
    CKEDITOR_SECRET_KEY:  __vault__::secret-mitopen/data/secrets>data>data>ckeditor>secret_key
    CKEDITOR_UPLOAD_URL:  __vault__::secret-mitopen/data/secrets>data>data>ckeditor>upload_url
    CSAIL_BASE_URL: https://cap.csail.mit.edu/
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ salt.boto_rds.get_endpoint('ol-mitopen-db-qa') }}/mitopen
    DEBUG: {{ env_data.DEBUG }}
    DUPLICATE_COURSES_URL: https://raw.githubusercontent.com/mitodl/open-resource-blacklists/master/duplicate_courses.yml
    EDX_API_ACCESS_TOKEN_URL: https://api.edx.org/oauth2/v1/access_token
    EDX_API_CLIENT_ID: __vault__::secret-mitopen/data/secrets>data>data>edx-api-client>id
    EDX_API_CLIENT_SECRET: __vault__::secret-mitopen/data/secrets>data>data>edx-api-client>secret
    EDX_API_URL: https://api.edx.org/catalog/v1/catalogs/10/courses
    EMBEDLY_KEY: __vault__::secret-operations/global/embedly>data>key
    ENABLE_INFINITE_CORRIDOR: {{ env_data.ENABLE_INFINITE_CORRIDOR }}
    GA_G_TRACKING_ID: {{ env_data.GA_G_TRACKING_ID }}
    GA_TRACKING_ID: {{ env_data.GA_TRACKING_ID }}
    GITHUB_ACCESS_TOKEN: __vault__::secret-operations/global/odlbot-github-access-token>data>value
    INDEXING_API_USERNAME: {{ env_data.INDEXING_API_USERNAME }}
    MAILGUN_FROM_EMAIL: 'MIT Open <no-reply@{{ env_data.MAILGUN_SENDER_DOMAIN }}'
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MAILGUN_URL: https://api.mailgun.net/v3/{{ env_data.MAILGUN_SENDER_DOMAIN }}
    MITPE_BASE_URL: https://professional.mit.edu/
    EDX_LEARNING_COURSE_BUCKET_NAME: {{ env_data.EDX_LEARNING_COURSE_BUCKET_NAME }}
    MITX_ONLINE_BASE_URL: https://mitxonline.mit.edu/
    MITX_ONLINE_COURSES_API_URL: https://mitxonline.mit.edu/api/courses/
    MITX_ONLINE_PROGRAMS_API_URL: https://mitxonline.mit.edu/api/programs/
    MITX_ONLINE_LEARNING_COURSE_BUCKET_NAME: mitx-etl-mitxonline-production
    NEW_RELIC_LOG: stdout
    NODE_MODULES_CACHE: False
    OCW_CONTENT_BUCKET_NAME: ocw-content-storage
    OCW_ITERATOR_CHUNK_SIZE: {{ env_data.OCW_ITERATOR_CHUNK_SIZE }}
    OCW_LEARNING_COURSE_BUCKET_NAME: ol-mitopen-course-data-{{ env_data.env_name }}
    OCW_NEXT_AWS_STORAGE_BUCKET_NAME: {{ env_data.OCW_NEXT_AWS_STORAGE_BUCKET_NAME }}
    OCW_NEXT_BASE_URL: {{ env_data.OCW_NEXT_BASE_URL }}
    OCW_NEXT_LIVE_BUCKET: {{ env_data.OCW_NEXT_LIVE_BUCKET }}
    OCW_NEXT_SEARCH_WEBHOOK_KEY: __vault__::secret-operations/global/update-search-data-webhook-key>data>value
    OCW_UPLOAD_IMAGE_ONLY: {{ env_data.OCW_UPLOAD_IMAGE_ONLY }}
    OLL_ALT_URL: https://openlearninglibrary.mit.edu/courses/
    OLL_API_ACCESS_TOKEN_URL: https://openlearninglibrary.mit.edu/oauth2/access_token/
    OLL_API_CLIENT_ID: __vault__::secret-mitopen/data/secrets>data>data>open-learning-library-client>client-id
    OLL_API_CLIENT_SECRET: __vault__::secret-mitopen/data/secrets>data>data>open-learning-library-client>client-secret
    OLL_API_URL: https://discovery.openlearninglibrary.mit.edu/api/v1/catalogs/1/courses/
    OLL_BASE_URL: https://openlearninglibrary.mit.edu/course/
    MITOPEN_ADMIN_EMAIL: cuddle-bunnies@mit.edu
    MITOPEN_BASE_URL: {{ env_data.MITOPEN_BASE_URL }}
    MITOPEN_COOKIE_DOMAIN: {{ env_data.MITOPEN_COOKIE_DOMAIN }}
    MITOPEN_COOKIE_NAME: {{ env_data.MITOPEN_COOKIE_NAME}}
    MITOPEN_CORS_ORIGIN_WHITELIST: '{{ env_data.CORS_URLS|tojson }}'
    CORS_ALLOWED_ORIGINS: '{{ env_data.CORS_URLS|tojson }}'
    CORS_ALLOWED_ORIGIN_REGEXES: "['^.+ocw-next.netlify.app$']"
    MITOPEN_DB_CONN_MAX_AGE: 0
    MITOPEN_DB_DISABLE_SSL: True
    MITOPEN_DEFAULT_SITE_KEY: micromasters
    MITOPEN_EMAIL_HOST:  __vault__::secret-operations/global/mit-smtp>data>relay_host
    MITOPEN_EMAIL_PASSWORD: __vault__::secret-operations/global/mit-smtp>data>relay_password
    MITOPEN_EMAIL_PORT: 587
    MITOPEN_EMAIL_TLS: True
    MITOPEN_EMAIL_USER: __vault__::secret-operations/global/mit-smtp>data>relay_username
    MITOPEN_ENVIRONMENT: {{ env_data.env_name }}
    MITOPEN_FROM_EMAIL: MITOpen <mitopen-support@mit.edu>
    MITOPEN_FRONTPAGE_DIGEST_MAX_POSTS: 10
    MITOPEN_JWT_SECRET: __vault__::secret-mitopen/data/secrets>data>data>jwt_secret
    MITOPEN_LOG_LEVEL: {{ env_data.app_log_level }}
    MITOPEN_SUPPORT_EMAIL: {{ env_data.MITOPEN_SUPPORT_EMAIL }}
    MITOPEN_USE_S3: True
    OPENSEARCH_DEFAULT_TIMEOUT: 30
    OPENSEARCH_HTTP_AUTH: __vault__::secret-mitopen/data/secrets>data>data>opensearch>http_auth
    OPENSEARCH_INDEX: {{ env_data.OPENSEARCH_INDEX}}
    OPENSEARCH_INDEXING_CHUNK_SIZE: 75
    OPENSEARCH_SHARD_COUNT: {{ env_data.OPENSEARCH_SHARD_COUNT }}
    OPENSEARCH_URL: {{ env_data.OPENSEARCH_URL}}
    PGBOUNCER_DEFAULT_POOL_SIZE: {{ env_data.PGBOUNCER_DEFAULT_POOL_SIZE}}
    PGBOUNCER_MAX_CLIENT_CONN: {{ env_data.PGBOUNCER_MAX_CLIENT_CONN }}
    PGBOUNCER_MIN_POOL_SIZE: {{ env_data.PGBOUNCER_MIN_POOL_SIZE }}
    PROLEARN_CATALOG_API_URL: https://prolearn.mit.edu/graphql
    SECRET_KEY: __vault__::secret-mitopen/data/secrets>data>data>django-secret-key
    SEE_BASE_URL: https://executive.mit.edu/
    SENTRY_DSN: __vault__::secret-operations/global/mitopen/sentry-dsn>data>value
    STATUS_TOKEN: __vault__::secret-mitopen/data/secrets>data>data>django-status-token
    TIKA_ACCESS_TOKEN: __vault__::secret-operations/tika/access-token>data>value
    TIKA_SERVER_ENDPOINT: {{ env_data.TIKA_SERVER_ENDPOINT }}
    USE_X_FORWARDED_HOST: True
    USE_X_FORWARDED_PORT: True
    XPRO_CATALOG_API_URL: https://{{ etl_xpro_host }}/api/programs/
    XPRO_COURSES_API_URL: https://{{ etl_xpro_host }}/api/courses/
    XPRO_LEARNING_COURSE_BUCKET_NAME: mitx-etl-xpro-production-mitxpro-production
    YOUTUBE_DEVELOPER_KEY: __vault__::secret-mitopen/data/secrets>data>data>youtube-developer-key
    YOUTUBE_FETCH_TRANSCRIPT_SCHEDULE_SECONDS: 21600
    YOUTUBE_FETCH_TRANSCRIPT_SLEEP_SECONDS: 20
    SOCIAL_AUTH_OL_OIDC_OIDC_ENDPOINT: https://{{ env_data.SSO_URL }}/realms/olapps
    OIDC_ENDPOINT: https://{{ env_data.SSO_URL }}/realms/olapps
    SOCIAL_AUTH_OL_OIDC_KEY: ol-open-client
    SOCIAL_AUTH_OL_OIDC_SECRET: __vault__::secret-mitopen/data/secrets>data>data>oidc-secret-key
    AUTHORIZATION_URL: https://{{ env_data.SSO_URL }}/realms/olapps/protocol/openid-connect/auth
    ACCESS_TOKEN_URL: https://{{ env_data.SSO_URL }}/realms/olapps/protocol/openid-connect/token
    USERINFO_URL: https://{{ env_data.SSO_URL }}/realms/olapps/protocol/openid-connect/userinfo

schedule:
  refresh_{{ env_data.app_name }}_configs:
    days: 5
    function: state.sls
    args:
      - heroku.update_heroku_config
