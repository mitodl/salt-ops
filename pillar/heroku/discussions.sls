{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}

{% set env_dict = {
    'ci': {
      'app_log_level': 'INFO',
      'app_name': 'odl-open-discussions-ci',
      'CELERY_WORKER_MAX_MEMORY_PER_CHILD': 125000,
      'CLOUDFRONT_DIST': 'd28ic9ywb63ioi',
      'CORS_URLS': ['https://micromasters-ci.odl.mit.edu', 'https://ocwnext-rc.odl.mit.edu', 'https://draft-qa.ocw.mit.edu', 'https://live-qa.ocw.mit.edu'],
      'DEBUG': False,
      'ELASTICSEARCH_INDEX': 'discussions-ci',
      'ELASTICSEARCH_SHARD_COUNT': 2,
      'ELASTICSEARCH_URL': 'https://search-opensearch-open-ci-gkxs5qardmug7pc472eznyfety.us-east-1.es.amazonaws.com',
      'ENABLE_INFINITE_CORRIDOR': True,
      'env_name': 'ci',
      'FEATURE_COURSE_UI': True,
      'GA_G_TRACKING_ID': 'G-N6Y7B0Z3JL',
      'GA_TRACKING_ID': 'UA-5145472-29',
      'INDEXING_API_USERNAME': 'od_mm_ci_api',
      'NEW_RELIC_APP_NAME': 'discussions-ci',
      'MAILGUN_SENDER_DOMAIN': 'discussions-mail.odl.mit.edu',
      'MICROMASTERS_BASE_URL': 'micromasters-ci.odl.mit.edu',
      'MITXPRO_BASE_URL': 'xpro-ci.odl.mit.edu',
      'OCW_ITERATOR_CHUNK_SIZE': 300,
      'OCW_NEXT_AWS_STORAGE_BUCKET_NAME': 'ol-ocw-studio-app-qa',
      'OCW_NEXT_BASE_URL': 'https://live-qa.ocw.mit.edu/',
      'OCW_NEXT_LIVE_BUCKET': 'ocw-content-live-qa',
      'OCW_UPLOAD_IMAGE_ONLY': True,
      'OPEN_DISCUSSIONS_BASE_URL': 'https://discussions-ci.odl.mit.edu',
      'OPEN_DISCUSSIONS_COOKIE_NAME': 'discussionsci',
      'OPEN_DISCUSSIONS_COOKIE_DOMAIN': 'odl.mit.edu',
      'OPEN_DISCUSSIONS_SUPPORT_EMAIL': 'odl-discussions-ci-support@mit.edu',
      'PGBOUNCER_DEFAULT_POOL_SIZE': 5,
      'PGBOUNCER_MAX_CLIENT_CONN': 20,
      'PGBOUNCER_MIN_POOL_SIZE': 5,
      'release_branch': 'master',
      'SOCIAL_AUTH_MICROMASTERS_LOGIN_URL': 'https://micromasters-ci.odl.mit.edu/discussions/',
      'SOCIAL_AUTH_SAML_SP_ENTITY_ID': 'https://discussions-ci.odl.mit.edu/saml/metadata',
      'TIKA_SERVER_ENDPOINT': 'https://tika-ci.odl.mit.edu',
      'vault_env_path': 'rc-apps',
      'env_stage': 'ci',
      },
    'rc': {
      'app_log_level': 'INFO',
      'app_name': 'odl-open-discussions-rc',
      'CELERY_WORKER_MAX_MEMORY_PER_CHILD': 125000,      
      'CLOUDFRONT_DIST': 'd1d3xcwjqmwwj2',
      'CORS_URLS': ['https://micromasters-rc.odl.mit.edu', 'https://ocwnext-rc.odl.mit.edu', 'https://ocw-next.netlify.app', 'https://ol-devops-ci.odl.mit.edu', 'https://draft-qa.ocw.mit.edu', 'https://live-qa.ocw.mit.edu'],
      'DEBUG': False,
      'ELASTICSEARCH_INDEX': 'discussions-rc',
      'ELASTICSEARCH_SHARD_COUNT': 2,
      'ELASTICSEARCH_URL': 'https://search-opensearch-open-qa-76e2mth7e5hvtclhuhh7uckoiu.us-east-1.es.amazonaws.com',
      'ENABLE_INFINITE_CORRIDOR': True,
      'env_name': 'rc',
      'FEATURE_COURSE_UI': True,
      'GA_G_TRACKING_ID': 'G-N6Y7B0Z3JL',
      'GA_TRACKING_ID': 'UA-5145472-29',
      'INDEXING_API_USERNAME': 'od_mm_rc_api',
      'NEW_RELIC_APP_NAME': 'discussions-rc',
      'MAILGUN_SENDER_DOMAIN': 'discussions-mail.odl.mit.edu',
      'MICROMASTERS_BASE_URL': 'micromasters-rc.odl.mit.edu',
      'MITXPRO_BASE_URL': 'xpro-rc.odl.mit.edu',
      'OCW_ITERATOR_CHUNK_SIZE': 300,
      'OCW_NEXT_AWS_STORAGE_BUCKET_NAME': 'ol-ocw-studio-app-qa',
      'OCW_NEXT_BASE_URL': 'https://live-qa.ocw.mit.edu/',
      'OCW_NEXT_LIVE_BUCKET': 'ocw-content-live-qa',
      'OCW_UPLOAD_IMAGE_ONLY': True,
      'OPEN_DISCUSSIONS_BASE_URL': 'https://discussions-rc.odl.mit.edu',
      'OPEN_DISCUSSIONS_COOKIE_NAME': 'discussionsrc',
      'OPEN_DISCUSSIONS_COOKIE_DOMAIN': 'odl.mit.edu',
      'OPEN_DISCUSSIONS_SUPPORT_EMAIL': 'odl-discussions-rc-support@mit.edu',
      'PGBOUNCER_DEFAULT_POOL_SIZE': 50,
      'PGBOUNCER_MAX_CLIENT_CONN': 500,
      'PGBOUNCER_MIN_POOL_SIZE': 20,
      'release_branch': 'release-candidate',
      'SOCIAL_AUTH_MICROMASTERS_LOGIN_URL': 'https://micromasters-rc.odl.mit.edu/login/edxorg/?next=/discussions/',
      'SOCIAL_AUTH_SAML_SP_ENTITY_ID': 'https://discussions-rc.odl.mit.edu/saml/metadata',
      'TIKA_SERVER_ENDPOINT': 'https://tika-qa.odl.mit.edu',
      'vault_env_path': 'rc-apps',
      'env_stage': 'qa',
      },
    'production': {
      'app_log_level': 'INFO',
      'app_name': 'odl-open-discussions',
      'CELERY_WORKER_MAX_MEMORY_PER_CHILD': 250000,
      'CLOUDFRONT_DIST': 'd2mcnjhkvrfuy2',
      'CORS_URLS': ['https://micromasters.mit.edu', 'https://ocwnext.odl.mit.edu', 'https://ocw-beta.odl.mit.edu', 'https://ocw-preview.odl.mit.edu', 'https://ocw-published.odl.mit.edu', "https://draft.ocw.mit.edu", "https://www.ocw.mit.edu", "https://ocw.mit.edu", 'https://live.ocw.mit.edu'],
      'DEBUG': False,
      'ENABLE_INFINITE_CORRIDOR': False,
      'env_name': 'production',
      'FEATURE_COURSE_UI': False,
      'ELASTICSEARCH_INDEX': 'discussions',
      'ELASTICSEARCH_SHARD_COUNT': 3,
      'ELASTICSEARCH_URL': 'https://search-opensearch-open-production-dg3wjt3eud45psxdrw3lz3k2ie.us-east-1.es.amazonaws.com',
      'GA_G_TRACKING_ID': 'G-5L2PYSTC4H',
      'GA_TRACKING_ID': 'UA-5145472-30',
      'INDEXING_API_USERNAME': 'od_mm_prod_api',
      'NEW_RELIC_APP_NAME': 'discussions-production',
      'MAILGUN_SENDER_DOMAIN': 'mail.open.mit.edu',
      'MICROMASTERS_BASE_URL': 'micromasters.mit.edu',
      'MITXPRO_BASE_URL': 'xpro.mit.edu',
      'OCW_ITERATOR_CHUNK_SIZE': 300,
      'OCW_NEXT_AWS_STORAGE_BUCKET_NAME': 'ol-ocw-studio-app-production',
      'OCW_NEXT_BASE_URL': 'https://ocw.mit.edu/',
      'OCW_NEXT_LIVE_BUCKET': 'ocw-content-live-production',
      'OCW_UPLOAD_IMAGE_ONLY': False,
      'OPEN_DISCUSSIONS_COOKIE_NAME': 'discussionsprod',
      'OPEN_DISCUSSIONS_BASE_URL': 'https://open.mit.edu',
      'OPEN_DISCUSSIONS_COOKIE_DOMAIN': 'mit.edu',
      'OPEN_DISCUSSIONS_SUPPORT_EMAIL': 'odl-discussions-support@mit.edu',
      'PGBOUNCER_DEFAULT_POOL_SIZE': 50,
      'PGBOUNCER_MAX_CLIENT_CONN': 500,
      'PGBOUNCER_MIN_POOL_SIZE': 20,
      'release_branch': 'release',
      'SOCIAL_AUTH_MICROMASTERS_LOGIN_URL': 'https://micromasters.mit.edu/login/edxorg/?next=/discussions/',
      'SOCIAL_AUTH_SAML_SP_ENTITY_ID': 'https://discussions.odl.mit.edu/saml/metadata',
      'TIKA_SERVER_ENDPOINT': 'https://tika-production.odl.mit.edu',
      'vault_env_path': 'production-apps',
      'env_stage': 'production',
      }
} %}
{% set env_data = env_dict[environment] %}
{% set business_unit = 'mit-open' %}
{% set pg_creds = salt.vault.cached_read('postgres-{}-opendiscussions/creds/opendiscussions'.format(env_data.vault_env_path), cache_prefix='heroku-opendiscussions') %}
{% set rds_endpoint = salt.boto_rds.get_endpoint('{env}-rds-postgresql-opendiscussions'.format(env=env_data.vault_env_path)) %}

{% set etl_micromasters_host = salt.sdb.get('sdb://consul/open-{}-etl-micromasters-host'.format(environment)) %}
{% set etl_xpro_host = salt.sdb.get('sdb://consul/open-{}-etl-xpro-host'.format(environment)) %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/global/heroku/odl-devops-api-key>data>value
  config_vars:
    AKISMET_API_KEY: __vault__::secret-{{ business_unit }}/global/akismet>data>api_key
    AKISMET_BLOG_URL: https://discussions-rc.odl.mit.edu
    ALGOLIA_API_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/algolia>data>api_key
    ALGOLIA_APP_ID: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/algolia>data>app_id
    ALLOWED_HOSTS: '["*"]'
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/mit-open-application-{{ env_data.env_stage }}>data>access_key
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/mit-open-application-{{ env_data.env_stage }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'odl-discussions-{{ env_data.env_name }}'
    CELERY_WORKER_MAX_MEMORY_PER_CHILD: {{ env_data.CELERY_WORKER_MAX_MEMORY_PER_CHILD }}
    CKEDITOR_ENVIRONMENT_ID:  __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/ckeditor>data>environment_id
    CKEDITOR_SECRET_KEY:  __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/ckeditor>data>secret_key
    CKEDITOR_UPLOAD_URL:  __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/ckeditor>data>upload_url
    CLOUDFRONT_DIST: {{ env_data.CLOUDFRONT_DIST }}
    CSAIL_BASE_URL: https://cap.csail.mit.edu/
    {% if env_data.env_name != 'ci' %}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/opendiscussions
    {% endif %}
    DEBUG: {{ env_data.DEBUG }}
    DUPLICATE_COURSES_URL: https://raw.githubusercontent.com/mitodl/open-resource-blacklists/master/duplicate_courses.yml
    EDX_API_ACCESS_TOKEN_URL: https://api.edx.org/oauth2/v1/access_token
    EDX_API_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/edx-api-client>data>id
    EDX_API_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ env_data.vault_env_path }}/edx-api-client>data>secret
    EDX_API_URL: https://api.edx.org/catalog/v1/catalogs/10/courses
    ELASTICSEARCH_HTTP_AUTH: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/elasticsearch>data>http_auth
    ELASTICSEARCH_INDEX: {{ env_data.ELASTICSEARCH_INDEX}}
    # This should match the nginx config client_max_body_size in apps_es.sls
    ELASTICSEARCH_INDEXING_CHUNK_SIZE: 75
    ELASTICSEARCH_SHARD_COUNT: {{ env_data.ELASTICSEARCH_SHARD_COUNT }}
    ELASTICSEARCH_URL: {{ env_data.ELASTICSEARCH_URL}}
    EMBEDLY_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/embedly_key>data>value
    ENABLE_INFINITE_CORRIDOR: {{ env_data.ENABLE_INFINITE_CORRIDOR }}
    FEATURE_ANONYMOUS_ACCESS: True
    FEATURE_ARTICLE_UI: True
    FEATURE_COMMENT_NOTIFICATIONS: True
    FEATURE_COURSE_FILE_SEARCH: True
    FEATURE_COURSE_UI: {{ env_data.FEATURE_COURSE_UI }}
    FEATURE_SPAM_EXEMPTIONS: True
    FEATURE_INDEX_UPDATES: True
    FEATURE_MOIRA: True
    FEATURE_PODCAST_APIS: True
    FEATURE_PROFILE_UI: True
    FEATURE_SAML_AUTH: True
    FEATURE_SEARCH_UI: True
    FEATURE_USE_NEW_BRANDING: True
    FEATURE_WIDGETS_UI: True
    GA_G_TRACKING_ID: {{ env_data.GA_G_TRACKING_ID }}
    GA_TRACKING_ID: {{ env_data.GA_TRACKING_ID }}
    GITHUB_ACCESS_TOKEN: __vault__::secret-{{ business_unit }}/global/odlbot-github-access-token>data>value
    INDEXING_API_USERNAME: {{ env_data.INDEXING_API_USERNAME }}
    MAILGUN_FROM_EMAIL: 'MIT Open <no-reply@{{ env_data.MAILGUN_SENDER_DOMAIN }}'
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MAILGUN_URL: https://api.mailgun.net/v3/{{ env_data.MAILGUN_SENDER_DOMAIN }}
    MICROMASTERS_BASE_URL: https://{{ env_data.MICROMASTERS_BASE_URL }}
    MICROMASTERS_CATALOG_API_URL: https://{{ etl_micromasters_host }}/api/v0/catalog/
    MICROMASTERS_COURSE_URL: https://{{ etl_micromasters_host }}/api/v0/courseruns/
    MICROMASTERS_EXTERNAL_LOGIN_URL: https://{{ env_data.MICROMASTERS_BASE_URL}}/discussions
    MITPE_BASE_URL: https://professional.mit.edu/
    {% if env_data.env_name != 'ci' %}
    MITX_ONLINE_BASE_URL: https://mitxonline.mit.edu/
    MITX_ONLINE_COURSES_API_URL: https://mitxonline.mit.edu/api/courses/
    MITX_ONLINE_PROGRAMS_API_URL: https://mitxonline.mit.edu/api/programs/
    MITX_ONLINE_LEARNING_COURSE_BUCKET_NAME: mitx-etl-mitxonline-production
    {% endif %}
    MIT_WS_CERTIFICATE: __vault__::secret-{{ business_unit }}/global/mit-application-certificate>data>certificate
    MIT_WS_PRIVATE_KEY: __vault__::secret-{{ business_unit }}/global/mit-application-certificate>data>private_key
    NEW_RELIC_LOG: stdout
    NODE_MODULES_CACHE: False
    OCW_CONTENT_BUCKET_NAME: ocw-content-storage
    OCW_ITERATOR_CHUNK_SIZE: {{ env_data.OCW_ITERATOR_CHUNK_SIZE }}
    OCW_LEARNING_COURSE_BUCKET_NAME: open-learning-course-data-{{ env_data.env_name }}
    OCW_NEXT_AWS_STORAGE_BUCKET_NAME: {{ env_data.OCW_NEXT_AWS_STORAGE_BUCKET_NAME }}
    OCW_NEXT_BASE_URL: {{ env_data.OCW_NEXT_BASE_URL }}
    OCW_NEXT_LIVE_BUCKET: {{ env_data.OCW_NEXT_LIVE_BUCKET }}
    OCW_NEXT_SEARCH_WEBHOOK_KEY: __vault__::secret-{{ business_unit }}/global/update-search-data-webhook-key>data>value
    OCW_UPLOAD_IMAGE_ONLY: {{ env_data.OCW_UPLOAD_IMAGE_ONLY }}
    OLL_ALT_URL: https://openlearninglibrary.mit.edu/courses/
    OLL_API_ACCESS_TOKEN_URL: https://openlearninglibrary.mit.edu/oauth2/access_token/
    OLL_API_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/open-learning-library-client>data>client-id
    OLL_API_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/open-learning-library-client>data>client-secret
    OLL_API_URL: https://discovery.openlearninglibrary.mit.edu/api/v1/catalogs/1/courses/
    OLL_BASE_URL: https://openlearninglibrary.mit.edu/course/
    OPEN_DISCUSSIONS_ADMIN_EMAIL: cuddle-bunnies@mit.edu
    OPEN_DISCUSSIONS_BASE_URL: {{ env_data.OPEN_DISCUSSIONS_BASE_URL }}
    OPEN_DISCUSSIONS_COOKIE_DOMAIN: {{ env_data.OPEN_DISCUSSIONS_COOKIE_DOMAIN }}
    OPEN_DISCUSSIONS_COOKIE_NAME: {{ env_data.OPEN_DISCUSSIONS_COOKIE_NAME}}
    OPEN_DISCUSSIONS_CORS_ORIGIN_WHITELIST: '{{ env_data.CORS_URLS|tojson }}'
    CORS_ALLOWED_ORIGINS: '{{ env_data.CORS_URLS|tojson }}'
    CORS_ALLOWED_ORIGIN_REGEXES: "['^.+ocw-next.netlify.app$']"
    OPEN_DISCUSSIONS_DB_CONN_MAX_AGE: 0
    OPEN_DISCUSSIONS_DB_DISABLE_SSL: True
    OPEN_DISCUSSIONS_DEFAULT_SITE_KEY: micromasters
    OPEN_DISCUSSIONS_EMAIL_HOST:  __vault__::secret-operations/global/mit-smtp>data>relay_host
    OPEN_DISCUSSIONS_EMAIL_PASSWORD: __vault__::secret-operations/global/mit-smtp>data>relay_password
    OPEN_DISCUSSIONS_EMAIL_PORT: 587
    OPEN_DISCUSSIONS_EMAIL_TLS: True
    OPEN_DISCUSSIONS_EMAIL_USER: __vault__::secret-operations/global/mit-smtp>data>relay_username
    OPEN_DISCUSSIONS_ENVIRONMENT: {{ env_data.env_name }}
    OPEN_DISCUSSIONS_FROM_EMAIL: MIT ODL Discussions <odl-discussions-support@mit.edu>
    OPEN_DISCUSSIONS_FRONTPAGE_DIGEST_MAX_POSTS: 10
    OPEN_DISCUSSIONS_JWT_SECRET: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ env_data.env_name }}/jwt_secret>data>value
    OPEN_DISCUSSIONS_LOG_LEVEL: {{ env_data.app_log_level }}
    OPEN_DISCUSSIONS_REDDIT_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/open-discussions-reddit>data>reddit_client_id
    OPEN_DISCUSSIONS_REDDIT_SECRET: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/open-discussions-reddit>data>reddit_secret
    OPEN_DISCUSSIONS_REDDIT_URL: __vault__::secret-{{ business_unit }}/{{ env_data.env_name }}/open-discussions-reddit>data>reddit_url
    OPEN_DISCUSSIONS_REDDIT_VALIDATE_SSL: True
    OPEN_DISCUSSIONS_SUPPORT_EMAIL: {{ env_data.OPEN_DISCUSSIONS_SUPPORT_EMAIL }}
    OPEN_DISCUSSIONS_USE_S3: True
    PGBOUNCER_DEFAULT_POOL_SIZE: {{ env_data.PGBOUNCER_DEFAULT_POOL_SIZE}}
    PGBOUNCER_MAX_CLIENT_CONN: {{ env_data.PGBOUNCER_MAX_CLIENT_CONN }}
    PGBOUNCER_MIN_POOL_SIZE: {{ env_data.PGBOUNCER_MIN_POOL_SIZE }}
    PROLEARN_CATALOG_API_URL: https://prolearn.mit.edu/graphql
    RECAPTCHA_SECRET_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/recaptcha-keys>data>secret_key
    RECAPTCHA_SITE_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/recaptcha-keys>data>site_key
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ env_data.env_name }}/django-secret-key>data>value
    SEE_BASE_URL: https://executive.mit.edu/
    SENTRY_DSN: __vault__::secret-operations/global/{{ business_unit }}/sentry-dsn>data>value
    SOCIAL_AUTH_MICROMASTERS_LOGIN_URL: {{ env_data.SOCIAL_AUTH_MICROMASTERS_LOGIN_URL }}
    SOCIAL_AUTH_SAML_CONTACT_NAME: ODL Support
    SOCIAL_AUTH_SAML_IDP_ATTRIBUTE_EMAIL: urn:oid:0.9.2342.19200300.100.1.3
    SOCIAL_AUTH_SAML_IDP_ATTRIBUTE_NAME: urn:oid:2.16.840.1.113730.3.1.241
    SOCIAL_AUTH_SAML_IDP_ATTRIBUTE_PERM_ID: urn:oid:1.3.6.1.4.1.5923.1.1.1.6
    SOCIAL_AUTH_SAML_IDP_ENTITY_ID: https://idp.mit.edu/shibboleth
    SOCIAL_AUTH_SAML_IDP_URL: https://idp.mit.edu/idp/profile/SAML2/Redirect/SSO
    SOCIAL_AUTH_SAML_IDP_X509: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/saml>data>idp_x509
    SOCIAL_AUTH_SAML_ORG_DISPLAYNAME: MIT Office of Digital Learning
    SOCIAL_AUTH_SAML_SECURITY_ENCRYPTED: True
    SOCIAL_AUTH_SAML_SP_ENTITY_ID: {{ env_data.SOCIAL_AUTH_SAML_SP_ENTITY_ID }}
    SOCIAL_AUTH_SAML_SP_PRIVATE_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/saml>data>private_key
    SOCIAL_AUTH_SAML_SP_PUBLIC_CERT: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/saml>data>public_cert
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/django-status-token>data>value
    TIKA_ACCESS_TOKEN: __vault__::secret-operations/{{ env_data.vault_env_path }}/tika/access-token>data>value
    TIKA_SERVER_ENDPOINT: {{ env_data.TIKA_SERVER_ENDPOINT }}
    USE_X_FORWARDED_HOST: True
    USE_X_FORWARDED_PORT: True
    XPRO_CATALOG_API_URL: https://{{ etl_xpro_host }}/api/programs/
    XPRO_COURSES_API_URL: https://{{ etl_xpro_host }}/api/courses/
    YOUTUBE_DEVELOPER_KEY: __vault__::secret-{{ business_unit }}/{{ environment }}/youtube-developer-key>data>value
    YOUTUBE_FETCH_TRANSCRIPT_SCHEDULE_SECONDS: 21600
    YOUTUBE_FETCH_TRANSCRIPT_SLEEP_SECONDS: 20

schedule:
  refresh_{{ env_data.app_name }}_configs:
    days: 5
    function: state.sls
    args:
      - heroku.update_heroku_config
