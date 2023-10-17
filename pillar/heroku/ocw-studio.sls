{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}

{% set env_dict = {
    'ci': {
      'app_name': 'ocw-studio-ci',
      'env': 'qa',
      'env_name': 'ci',
      'CONCOURSE_URL': 'https://cicd-ci.odl.mit.edu',
      'DRIVE_SHARED_ID': '',
      'DRIVE_UPLOADS_PARENT_FOLDER_ID': '',
      'DRIVE_VIDEO_UPLOADS_PARENT_FOLDER_ID': '1H4HCvbmY7v5YZFeqSlbCI1TFC5MXTMY4',
      'FEATURE_USE_LOCAL_STARTERS': 'True',
      'FEATURE_SORTABLE_SELECT_PRESERVE_SEARCH_TEXT': 'True',
      'FEATURE_SELECT_FIELD_INFINITE_SCROLL': 'True',
      'FEATURE_SORTABLE_SELECT_HIDE_SELECTED': 'True',
      'FEATURE_SORTABLE_SELECT_QUICK_ADD': 'True',
      'GIT_DOMAIN': 'github.mit.edu',
      'GITHUB_ORGANIZATION': 'ocw-content-ci',
      'GITHUB_WEBHOOK_BRANCH': '',
      'GITHUB_APP_ID': '',
      'GITHUB_RATE_LIMIT_CHECK': 'False',
      'OCW_GTM_ACCOUNT_ID': 'GTM-PJMJGF6',
      'GTM_ACCOUNT_ID': 'GTM-5JZ7X78',
      'MAILGUN_SENDER_DOMAIN': 'ocw-ci.mail.odl.mit.edu',
      'OCW_IMPORT_STARTER_SLUG': 'course',
      'OCW_COURSE_STARTER_SLUG': 'ocw-course-v2',
      'OCW_MASS_BUILD_BATCH_SIZE': '20',
      'OCW_MASS_BUILD_MAX_IN_FLIGHT': '10',
      'OCW_STUDIO_BASE_URL': 'https://ocw-studio-ci.odl.mit.edu/',
      'OCW_STUDIO_DRAFT_URL': '',
      'OCW_STUDIO_LIVE_URL': '',
      'OCW_STUDIO_LOG_LEVEL': 'INFO',
      'OCW_STUDIO_SUPPORT_EMAIL': 'ocw-studio-ci-support@mit.edu',
      'OPEN_DISCUSSIONS_URL': 'https://discussions-ci.odl.mit.edu',
      'SEARCH_API_URL': 'https://discussions-ci.odl.mit.edu/api/v0/search/',
      'sentry_log_level': 'WARN',
      'SITE_NAME': 'MIT OCW Studio CI',
      'SOCIAL_AUTH_SAML_SP_ENTITY_ID': 'https://ocw-studio-ci.odl.mit.edu/saml/metadata',
      'vault_env_path': 'rc-apps',
      'VIDEO_TRANSCODE_QUEUE': 'ocw-studio-mediaconvert-queue-ci',
      'youtube_project_id': 'ovs-youtube-qa',
      'sitemap_domain': 'live-ci.ocw.mit.edu',
      'OCW_HUGO_THEMES_SENTRY_DSN': ''
      },
    'rc': {
      'app_name': 'ocw-studio-rc',
      'env': 'qa',
      'env_name': 'rc',
      'CONCOURSE_URL': 'https://cicd-qa.odl.mit.edu',
      'DRIVE_SHARED_ID': '0AErNBMZMmOz3Uk9PVA',
      'DRIVE_UPLOADS_PARENT_FOLDER_ID': '1H4HCvbmY7v5YZFeqSlbCI1TFC5MXTMY4',
      'FEATURE_USE_LOCAL_STARTERS': 'True',
      'FEATURE_SORTABLE_SELECT_PRESERVE_SEARCH_TEXT': 'True',
      'FEATURE_SELECT_FIELD_INFINITE_SCROLL': 'True',
      'FEATURE_SORTABLE_SELECT_HIDE_SELECTED': 'True',
      'FEATURE_SORTABLE_SELECT_QUICK_ADD': 'True',
      'GIT_DOMAIN': 'github.mit.edu',
      'GTM_ACCOUNT_ID': 'GTM-57BZ8PN',
      'OCW_GTM_ACCOUNT_ID': 'GTM-PJMJGF6',
      'GITHUB_APP_ID': 12,
      'GITHUB_ORGANIZATION': 'ocw-content-rc',
      'GITHUB_WEBHOOK_BRANCH': 'release-candidate',
      'GITHUB_RATE_LIMIT_CHECK': 'False',
      'MAILGUN_SENDER_DOMAIN': 'ocw-rc.mail.odl.mit.edu',
      'OCW_IMPORT_STARTER_SLUG': 'ocw-course',
      'OCW_COURSE_STARTER_SLUG': 'ocw-course-v2',
      'OCW_MASS_BUILD_BATCH_SIZE': '160',
      'OCW_MASS_BUILD_MAX_IN_FLIGHT': '20',
      'OCW_STUDIO_BASE_URL': 'https://ocw-studio-rc.odl.mit.edu/',
      'OCW_STUDIO_DRAFT_URL': 'https://draft-qa.ocw.mit.edu/',
      'OCW_STUDIO_LIVE_URL': 'https://live-qa.ocw.mit.edu/',
      'OCW_STUDIO_LOG_LEVEL': 'INFO',
      'OCW_STUDIO_SUPPORT_EMAIL': 'ocw-studio-rc-support@mit.edu',
      'OPEN_DISCUSSIONS_URL': 'https://discussions-rc.odl.mit.edu',
      'SEARCH_API_URL': 'https://discussions-rc.odl.mit.edu/api/v0/search/',
      'sentry_log_level': 'WARN',
      'SITE_NAME': 'MIT OCW Studio RC',
      'SOCIAL_AUTH_SAML_SP_ENTITY_ID': 'https://ocw-studio-rc.odl.mit.edu/saml/metadata',
      'vault_env_path': 'rc-apps',
      'VIDEO_TRANSCODE_QUEUE': 'ocw-studio-mediaconvert-queue-qa',
      'youtube_project_id': 'ocw-studio-qa',
      'sitemap_domain': 'live-qa.ocw.mit.edu',
      'OCW_HUGO_THEMES_SENTRY_DSN': 'https://eee58f41dda54d2b814296e12dced4b7@o48788.ingest.sentry.io/5304953'
      },
    'production': {
      'app_name': 'ocw-studio',
      'env': 'production',
      'env_name': 'production',
      'CONCOURSE_URL': 'https://cicd.odl.mit.edu',
      'DRIVE_SHARED_ID': '0AIZerpz9jimTUk9PVA',
      'DRIVE_UPLOADS_PARENT_FOLDER_ID': '',
      'FEATURE_USE_LOCAL_STARTERS': 'False',
      'FEATURE_SORTABLE_SELECT_PRESERVE_SEARCH_TEXT': 'True',
      'FEATURE_SELECT_FIELD_INFINITE_SCROLL': 'True',
      'FEATURE_SORTABLE_SELECT_HIDE_SELECTED': 'True',
      'FEATURE_SORTABLE_SELECT_QUICK_ADD': 'True',
      'GIT_DOMAIN': 'github.mit.edu',
      'GITHUB_APP_ID': 13,
      'GITHUB_RATE_LIMIT_CHECK': 'False',
      'GTM_ACCOUNT_ID': 'GTM-MQCSLSQ',
      'OCW_GTM_ACCOUNT_ID': 'GTM-NMQZ25T',
      'GITHUB_ORGANIZATION': 'mitocwcontent',
      'GITHUB_WEBHOOK_BRANCH': 'release',
      'MAILGUN_SENDER_DOMAIN': 'ocw.mail.odl.mit.edu',
      'OCW_IMPORT_STARTER_SLUG': 'ocw-course',
      'OCW_COURSE_STARTER_SLUG': 'ocw-course-v2',
      'OCW_MASS_BUILD_BATCH_SIZE': '160',
      'OCW_MASS_BUILD_MAX_IN_FLIGHT': '20',
      'OCW_STUDIO_BASE_URL': 'https://ocw-studio.odl.mit.edu/',
      'OCW_STUDIO_DRAFT_URL': 'https://draft.ocw.mit.edu/',
      'OCW_STUDIO_LIVE_URL': 'https://ocw.mit.edu/',
      'OCW_STUDIO_LOG_LEVEL': 'INFO',
      'OCW_STUDIO_SUPPORT_EMAIL': 'ocw-studio-support@mit.edu',
      'OPEN_DISCUSSIONS_URL': 'https://open.mit.edu',
      'SEARCH_API_URL': 'https://open.mit.edu/api/v0/search/',
      'sentry_log_level': 'WARN',
      'SITE_NAME': 'MIT OCW Studio',
      'SOCIAL_AUTH_SAML_SP_ENTITY_ID': 'https://ocw-studio.odl.mit.edu/saml/metadata',
      'vault_env_path': 'production-apps',
      'VIDEO_TRANSCODE_QUEUE': 'ocw-studio-mediaconvert-queue-production',
      'youtube_project_id': 'ocw-studio-qa',
      'sitemap_domain': 'ocw.mit.edu',
      'OCW_HUGO_THEMES_SENTRY_DSN': 'https://eee58f41dda54d2b814296e12dced4b7@o48788.ingest.sentry.io/5304953'
      }
} %}
{% set env_data = env_dict[environment] %}
{% set app = 'ocw-studio' %}
{% set business_unit = 'open-courseware' %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/global/heroku/odl-devops-api-key>data>value
  config_vars:
    ALLOWED_HOSTS: '["*"]'
    API_BEARER_TOKEN: __vault__::secret-concourse/data/ocw/api-bearer-token>data>data>value
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/ocw-studio-app-{{ env_data.env }}>data>access_key
    AWS_ACCOUNT_ID:  __vault__::secret-{{ business_unit }}/ocw-studio/{{ environment }}/aws_account_id>data>value
    AWS_ROLE_NAME: 'service-role-mediaconvert-ocw-studio-{{ env_data.env }}'
    AWS_REGION: us-east-1
    AWS_ARTIFACTS_BUCKET_NAME: 'ol-eng-artifacts'
    AWS_PREVIEW_BUCKET_NAME: 'ocw-content-draft-{{ env_data.env }}'
    AWS_PUBLISH_BUCKET_NAME: 'ocw-content-live-{{ env_data.env }}'
    AWS_OFFLINE_PREVIEW_BUCKET_NAME: 'ocw-content-offline-draft-{{ env_data.env }}'
    AWS_OFFLINE_PUBLISH_BUCKET_NAME: 'ocw-content-offline-live-{{ env_data.env }}'
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/ocw-studio-app-{{ env_data.env }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'ol-ocw-studio-app-{{ env_data.env }}'
    AWS_MAX_CONCURRENT_CONNECTIONS: 100
    CONTENT_SYNC_BACKEND: content_sync.backends.github.GithubBackend
    CONTENT_SYNC_PIPELINE: content_sync.pipelines.concourse.ConcourseGithubPipeline
    CONTENT_SYNC_THEME_PIPELINE: content_sync.pipelines.concourse.ThemeAssetsPipeline
    CONCOURSE_URL: {{ env_data.CONCOURSE_URL }}
    CONCOURSE_USERNAME: oldevops
    CONCOURSE_PASSWORD: __vault__::secret-concourse/data/web>data>data>admin_password
    {% if env_data.env_name != 'ci' %}
    {% set pg_creds = salt.vault.cached_read('postgres-ocw-studio-applications-{}/creds/app'.format(env_data.env), cache_prefix='heroku-ocw-studio-' ~ env_data.env) %}
    {% set rds_endpoint = salt.boto_rds.get_endpoint('ocw-studio-db-applications-{}'.format(env_data.env)) %}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/ocw_studio
    ENV_NAME: {{ env_data.env_name }}
    GIT_API_URL: "https://github.mit.edu/api/v3"
    {% endif %}
    DRIVE_S3_UPLOAD_PREFIX: gdrive_uploads
    DRIVE_SERVICE_ACCOUNT_CREDS: __vault__::secret-{{ business_unit }}/ocw-studio/{{ environment }}/gdrive-service-json>data>value
    DRIVE_SHARED_ID: {{ env_data.DRIVE_SHARED_ID }}
    DRIVE_UPLOADS_PARENT_FOLDER_ID: {{ env_data.DRIVE_UPLOADS_PARENT_FOLDER_ID }}
    FEATURE_USE_LOCAL_STARTERS: {{ env_data.FEATURE_USE_LOCAL_STARTERS }}
    FEATURE_SORTABLE_SELECT_PRESERVE_SEARCH_TEXT: {{ env_data.FEATURE_SORTABLE_SELECT_PRESERVE_SEARCH_TEXT }}
    FEATURE_SELECT_FIELD_INFINITE_SCROLL: {{ env_data.FEATURE_SELECT_FIELD_INFINITE_SCROLL }}
    FEATURE_SORTABLE_SELECT_HIDE_SELECTED: {{ env_data.FEATURE_SORTABLE_SELECT_HIDE_SELECTED }}
    FEATURE_SORTABLE_SELECT_QUICK_ADD: {{ env_data.FEATURE_SORTABLE_SELECT_QUICK_ADD }}
    GIT_DEFAULT_USER_NAME: 'OCW Studio Bot'
    GIT_DOMAIN: {{ env_data.GIT_DOMAIN }}
    GIT_ORGANIZATION: {{ env_data.GITHUB_ORGANIZATION }}
    GIT_TOKEN: __vault__::secret-{{ business_unit }}/ocw-studio/{{ environment }}/github-user-token>data>value
    GITHUB_APP_ID: {{ env_data.GITHUB_APP_ID }}
    GITHUB_APP_PRIVATE_KEY: __vault__::secret-ocw-studio/data/app-config>data>data>github_app_private_key  # the double >data>data is because this is a kv-v2 mount
    GITHUB_WEBHOOK_KEY: __vault__::secret-ocw-studio/data/app-config>data>data>github_shared_secret  # the double >data>data is because this is a kv-v2 mount
    GITHUB_WEBHOOK_BRANCH: {{ env_data.GITHUB_WEBHOOK_BRANCH }}
    GITHUB_RATE_LIMIT_CHECK: {{ env_data.GITHUB_RATE_LIMIT_CHECK }}
    GTM_ACCOUNT_ID: {{ env_data.GTM_ACCOUNT_ID }}
    OCW_GTM_ACCOUNT_ID: {{ env_data.OCW_GTM_ACCOUNT_ID }}
    MAILGUN_FROM_EMAIL: 'MIT OCW <no-reply@{{ env_data.MAILGUN_SENDER_DOMAIN }}'
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MAILGUN_URL: https://api.mailgun.net/v3/{{ env_data.MAILGUN_SENDER_DOMAIN }}
    MITOL_MAIL_FROM_EMAIL: ocw-prod-support@mit.edu
    MITOL_MAIL_REPLY_TO_ADDRESS: ocw-prod-support@mit.edu
    OCW_IMPORT_STARTER_SLUG: {{ env_data.OCW_IMPORT_STARTER_SLUG }}
    OCW_COURSE_STARTER_SLUG: {{ env_data.OCW_COURSE_STARTER_SLUG }}
    OCW_STUDIO_ADMIN_EMAIL: cuddle-bunnies@mit.edu
    OCW_STUDIO_BASE_URL: {{ env_data.OCW_STUDIO_BASE_URL }}
    OCW_STUDIO_DRAFT_URL: {{ env_data.OCW_STUDIO_DRAFT_URL}}
    OCW_STUDIO_LIVE_URL: {{ env_data.OCW_STUDIO_LIVE_URL}}
    OCW_STUDIO_DB_CONN_MAX_AGE: 0
    OCW_STUDIO_DB_DISABLE_SSL: True
    OCW_STUDIO_ENVIRONMENT: {{ env_data.env_name }}
    OCW_STUDIO_LOG_LEVEL: {{ env_data.OCW_STUDIO_LOG_LEVEL }}
    OCW_STUDIO_SUPPORT_EMAIL: {{ env_data.OCW_STUDIO_SUPPORT_EMAIL }}
    OCW_STUDIO_USE_S3: True
    OCW_MASS_BUILD_BATCH_SIZE: {{ env_data.OCW_MASS_BUILD_BATCH_SIZE }}
    OCW_MASS_BUILD_MAX_IN_FLIGHT: {{ env_data.OCW_MASS_BUILD_MAX_IN_FLIGHT }}
    OCW_NEXT_SEARCH_WEBHOOK_KEY: __vault__::secret-{{ business_unit }}/global/update-search-data-webhook-key>data>value
    OPEN_DISCUSSIONS_URL: {{ env_data.OPEN_DISCUSSIONS_URL }}
    PREPUBLISH_ACTIONS: videos.tasks.update_transcripts_for_website,videos.youtube.update_youtube_metadata,content_sync.tasks.update_website_in_root_website
    SEARCH_API_URL: {{ env_data.SEARCH_API_URL }}
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ app }}/{{ environment }}/django-secret-key>data>value
    SENTRY_DSN: __vault__::secret-operations/global/{{ business_unit }}/ocw-studio/sentry-dsn>data>value
    SENTRY_LOG_LEVEL: {{ env_data.sentry_log_level }}
    SITEMAP_DOMAIN: {{ env_data.sitemap_domain }}
    SOCIAL_AUTH_SAML_CONTACT_NAME: Open Learning Support
    SOCIAL_AUTH_SAML_IDP_ATTRIBUTE_EMAIL: "urn:oid:0.9.2342.19200300.100.1.3"
    SOCIAL_AUTH_SAML_IDP_ATTRIBUTE_NAME: "urn:oid:2.16.840.1.113730.3.1.241"
    SOCIAL_AUTH_SAML_IDP_ATTRIBUTE_PERM_ID: "urn:oid:1.3.6.1.4.1.5923.1.1.1.6"
    SOCIAL_AUTH_SAML_IDP_ENTITY_ID: https://idp.mit.edu/shibboleth
    SOCIAL_AUTH_SAML_IDP_URL: https://idp.mit.edu/idp/profile/SAML2/Redirect/SSO
    SOCIAL_AUTH_SAML_LOGIN_URL: https://idp.mit.edu/idp/profile/SAML2/Redirect/SSO
    SOCIAL_AUTH_SAML_IDP_X509: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/saml>data>idp_x509
    SOCIAL_AUTH_SAML_ORG_DISPLAYNAME: MIT Open Learning
    SOCIAL_AUTH_SAML_SECURITY_ENCRYPTED: True
    SOCIAL_AUTH_SAML_SP_ENTITY_ID: {{ env_data.SOCIAL_AUTH_SAML_SP_ENTITY_ID }}
    SOCIAL_AUTH_SAML_SP_PRIVATE_KEY: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/saml>data>private_key
    SOCIAL_AUTH_SAML_SP_PUBLIC_CERT: __vault__::secret-operations/{{ env_data.vault_env_path }}/{{ business_unit }}/saml>data>public_cert
    STATUS_TOKEN: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ app }}/{{ environment }}/django-status-token>data>value
    THREEPLAY_API_KEY: __vault__::secret-operations/global/{{ business_unit }}/ocw-studio/threeplay_api_key>data>value
    THREEPLAY_CALLBACK_KEY: __vault__:gen_if_missing:secret-operations/global/{{ business_unit }}/ocw-studio/threeplay_callback_key>data>value
    USE_X_FORWARDED_PORT: True
    VIDEO_S3_TRANSCODE_ENDPOINT: __vault__::secret-ocw-studio/data/video_s3_transcode_endpoint>data>data>value
    VIDEO_S3_TRANSCODE_PREFIX: aws_mediaconvert_transcodes
    VIDEO_TRANSCODE_QUEUE: {{ env_data.VIDEO_TRANSCODE_QUEUE }}
    YT_ACCESS_TOKEN: __vault__::secret-{{ business_unit }}/{{ app }}/{{ env_data.vault_env_path }}/youtube-credentials>data>access_token
    YT_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ app }}/{{ env_data.vault_env_path }}/youtube-credentials>data>client_id
    YT_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ app }}/{{ env_data.vault_env_path }}/youtube-credentials>data>client_secret
    YT_PROJECT_ID: {{ env_data.youtube_project_id }}
    YT_REFRESH_TOKEN: __vault__::secret-{{ business_unit }}/{{ app }}/{{ env_data.vault_env_path }}/youtube-credentials>data>refresh_token
    OCW_HUGO_THEMES_SENTRY_DSN: {{ env_data.OCW_HUGO_THEMES_SENTRY_DSN }}
