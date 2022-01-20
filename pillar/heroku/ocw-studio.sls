{% set minion_id = salt.grains.get('id', '') %}
{% set environment = minion_id.split('-')[-1] %}

{% set env_dict = {
    'ci': {
      'app_name': 'ocw-studio-ci',
      'env': 'qa',
      'env_name': 'ci',
      'CONCOURSE_URL': 'https://cicd-qa.odl.mit.edu',
      'DRIVE_SHARED_ID': '',
      'DRIVE_UPLOADS_PARENT_FOLDER_ID': '',
      'DRIVE_VIDEO_UPLOADS_PARENT_FOLDER_ID': '1H4HCvbmY7v5YZFeqSlbCI1TFC5MXTMY4',
      'FEATURE_USE_LOCAL_STARTERS': 'True',
      'GIT_DOMAIN': 'github.mit.edu',
      'GITHUB_ORGANIZATION': 'ocw-content-ci',
      'GITHUB_WEBHOOK_BRANCH': '',
      'GITHUB_RATE_LIMIT_CHECK': 'False',
      'GTM_ACCOUNT_ID': 'GTM-5JZ7X78',
      'MAILGUN_SENDER_DOMAIN': 'ocw-ci.mail.odl.mit.edu',
      'OCW_IMPORT_STARTER_SLUG': 'course',
      'OCW_STUDIO_BASE_URL': 'https://ocw-studio-ci.odl.mit.edu/',
      'OCW_STUDIO_DRAFT_URL': '',
      'OCW_STUDIO_LIVE_URL': '',
      'OCW_STUDIO_LOG_LEVEL': 'INFO',
      'OCW_STUDIO_SUPPORT_EMAIL': 'ocw-studio-ci-support@mit.edu',
      'sentry_log_level': 'WARN',
      'SITE_NAME': 'MIT OCW Studio CI',
      'SOCIAL_AUTH_SAML_SP_ENTITY_ID': 'https://ocw-studio-ci.odl.mit.edu/saml/metadata',
      'vault_env_path': 'rc-apps',
      'youtube_project_id': 'ovs-youtube-qa'
      },
    'rc': {
      'app_name': 'ocw-studio-rc',
      'env': 'qa',
      'env_name': 'rc',
      'CONCOURSE_URL': 'https://cicd-qa.odl.mit.edu',
      'DRIVE_SHARED_ID': '0AErNBMZMmOz3Uk9PVA',
      'DRIVE_UPLOADS_PARENT_FOLDER_ID': '1H4HCvbmY7v5YZFeqSlbCI1TFC5MXTMY4',
      'FEATURE_USE_LOCAL_STARTERS': 'True',
      'GIT_DOMAIN': 'github.mit.edu',
      'GTM_ACCOUNT_ID': 'GTM-57BZ8PN',
      'GITHUB_ORGANIZATION': 'ocw-content-rc',
      'GITHUB_WEBHOOK_BRANCH': 'release-candidate',
      'GITHUB_RATE_LIMIT_CHECK': 'False',
      'MAILGUN_SENDER_DOMAIN': 'ocw-rc.mail.odl.mit.edu',
      'OCW_IMPORT_STARTER_SLUG': 'ocw-course',
      'OCW_STUDIO_BASE_URL': 'https://ocw-studio-rc.odl.mit.edu/',
      'OCW_STUDIO_DRAFT_URL': 'https://ocw-draft-qa.global.ssl.fastly.net/',
      'OCW_STUDIO_LIVE_URL': 'https://ocw-live-qa.global.ssl.fastly.net/',
      'OCW_STUDIO_LOG_LEVEL': 'INFO',
      'OCW_STUDIO_SUPPORT_EMAIL': 'ocw-studio-rc-support@mit.edu',
      'sentry_log_level': 'WARN',
      'SITE_NAME': 'MIT OCW Studio RC',
      'SOCIAL_AUTH_SAML_SP_ENTITY_ID': 'https://ocw-studio-rc.odl.mit.edu/saml/metadata',
      'vault_env_path': 'rc-apps',
      'youtube_project_id': 'ocw-studio-qa'
      },
    'production': {
      'app_name': 'ocw-studio',
      'env': 'production',
      'env_name': 'production',
      'CONCOURSE_URL': 'https://cicd.odl.mit.edu',
      'DRIVE_SHARED_ID': '0AIZerpz9jimTUk9PVA',
      'DRIVE_UPLOADS_PARENT_FOLDER_ID': '',
      'FEATURE_USE_LOCAL_STARTERS': 'False',
      'GIT_DOMAIN': 'github.com',
      'GITHUB_RATE_LIMIT_CHECK': 'True',
      'GTM_ACCOUNT_ID': 'GTM-MQCSLSQ',
      'GITHUB_ORGANIZATION': 'mitocwcontent',
      'GITHUB_WEBHOOK_BRANCH': 'release',
      'MAILGUN_SENDER_DOMAIN': 'ocw.mail.odl.mit.edu',
      'OCW_IMPORT_STARTER_SLUG': 'ocw-course',
      'OCW_STUDIO_BASE_URL': 'https://ocw-studio.odl.mit.edu/',
      'OCW_STUDIO_DRAFT_URL': 'https://ocw-preview.odl.mit.edu/',
      'OCW_STUDIO_LIVE_URL': 'https://ocw-published.odl.mit.edu/',
      'OCW_STUDIO_LOG_LEVEL': 'INFO',
      'OCW_STUDIO_SUPPORT_EMAIL': 'ocw-studio-support@mit.edu',
      'sentry_log_level': 'WARN',
      'SITE_NAME': 'MIT OCW Studio',
      'SOCIAL_AUTH_SAML_SP_ENTITY_ID': 'https://ocw-studio.odl.mit.edu/saml/metadata',
      'vault_env_path': 'production-apps',
      'youtube_project_id': ''
      }
} %}
{% set env_data = env_dict[environment] %}
{% set app = 'ocw-studio' %}
{% set business_unit = 'open-courseware' %}

proxy:
  proxytype: heroku

heroku:
  app_name: {{ env_data.app_name }}
  api_key: __vault__::secret-operations/heroku/odl-devops-api-key>data>value
  config_vars:
    ALLOWED_HOSTS: '["*"]'
    API_BEARER_TOKEN: __vault__::secret-concourse/data/ocw/api-bearer-token>data>data>value
    AWS_ACCESS_KEY_ID:  __vault__:cache:aws-mitx/creds/ocw-studio-app-{{ env_data.env }}>data>access_key
    AWS_ACCOUNT_ID:  __vault__::secret-{{ business_unit }}/ocw-studio/{{ environment }}/aws_account_id>data>value
    AWS_ROLE_NAME: 'service-role-mediaconvert-ocw-studio-{{ env_data.env }}'
    AWS_REGION: us-east-1
    AWS_PREVIEW_BUCKET_NAME: 'ocw-content-draft-{{ env_data.env }}'
    AWS_PUBLISH_BUCKET_NAME: 'ocw-content-live-{{ env_data.env }}'
    AWS_SECRET_ACCESS_KEY: __vault__:cache:aws-mitx/creds/ocw-studio-app-{{ env_data.env }}>data>secret_key
    AWS_STORAGE_BUCKET_NAME: 'ol-ocw-studio-app-{{ env_data.env }}'
    CONTENT_SYNC_BACKEND: content_sync.backends.github.GithubBackend
    CONTENT_SYNC_PIPELINE: content_sync.pipelines.concourse.ConcourseGithubPipeline
    CONCOURSE_URL: {{ env_data.CONCOURSE_URL }}
    CONCOURSE_USERNAME: oldevops
    CONCOURSE_PASSWORD: __vault__::secret-concourse/data/web>data>data>admin_password
    {% if env_data.env_name != 'ci' %}
    {% set pg_creds = salt.vault.cached_read('postgres-ocw-studio-applications-{}/creds/app'.format(env_data.env), cache_prefix='heroku-ocw-studio-' ~ env_data.env) %}
    {% set rds_endpoint = salt.boto_rds.get_endpoint('ocw-studio-db-applications-{}'.format(env_data.env)) %}
    DATABASE_URL: postgres://{{ pg_creds.data.username }}:{{ pg_creds.data.password }}@{{ rds_endpoint }}/ocw_studio
    {% endif %}
    DRIVE_S3_UPLOAD_PREFIX: gdrive_uploads
    DRIVE_SERVICE_ACCOUNT_CREDS: __vault__::secret-{{ business_unit }}/ocw-studio/{{ environment }}/gdrive-service-json>data>value
    DRIVE_SHARED_ID: {{ env_data.DRIVE_SHARED_ID }}
    DRIVE_UPLOADS_PARENT_FOLDER_ID: {{ env_data.DRIVE_UPLOADS_PARENT_FOLDER_ID }}
    FEATURE_USE_LOCAL_STARTERS: {{ env_data.FEATURE_USE_LOCAL_STARTERS }}
    {% if environment == "rc" %}
    GIT_API_URL: "https://github.mit.edu/api/v3"
    {% endif %}
    GIT_DOMAIN: {{ env_data.GIT_DOMAIN }}
    GIT_ORGANIZATION: {{ env_data.GITHUB_ORGANIZATION }}
    GIT_TOKEN: __vault__::secret-{{ business_unit }}/ocw-studio/{{ environment }}/github-user-token>data>value
    GITHUB_WEBHOOK_KEY: __vault__::secret-ocw-studio/data/app-config>data>data>github_shared_secret  # the double >data>data is because this is a kv-v2 mount
    GITHUB_WEBHOOK_BRANCH: {{ env_data.GITHUB_WEBHOOK_BRANCH }}
    GITHUB_RATE_LIMIT_CHECK: {{ env_data.GITHUB_RATE_LIMIT_CHECK }}
    GTM_ACCOUNT_ID: {{ env_data.GTM_ACCOUNT_ID }}
    MAILGUN_FROM_EMAIL: 'MIT OCW <no-reply@{{ env_data.MAILGUN_SENDER_DOMAIN }}'
    MAILGUN_KEY: __vault__::secret-operations/global/mailgun-api-key>data>value
    MAILGUN_SENDER_DOMAIN: {{ env_data.MAILGUN_SENDER_DOMAIN }}
    MAILGUN_URL: https://api.mailgun.net/v3/{{ env_data.MAILGUN_SENDER_DOMAIN }}
    OCW_IMPORT_STARTER_SLUG: {{ env_data.OCW_IMPORT_STARTER_SLUG }}
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
    PREPUBLISH_ACTIONS: videos.tasks.update_transcripts_for_website,videos.youtube.update_youtube_metadata
    SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ app }}/{{ environment }}/django-secret-key>data>value
    SENTRY_DSN: __vault__::secret-operations/global/{{ business_unit }}/ocw-studio/sentry-dsn>data>value
    SENTRY_LOG_LEVEL: {{ env_data.sentry_log_level }}
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
    VIDEO_S3_TRANSCODE_PREFIX: aws_mediaconvert_transcodes
    YT_ACCESS_TOKEN: __vault__::secret-{{ business_unit }}/{{ app }}/{{ env_data.vault_env_path }}/youtube-credentials>data>access_token
    YT_CLIENT_ID: __vault__::secret-{{ business_unit }}/{{ app }}/{{ env_data.vault_env_path }}/youtube-credentials>data>client_id
    YT_CLIENT_SECRET: __vault__::secret-{{ business_unit }}/{{ app }}/{{ env_data.vault_env_path }}/youtube-credentials>data>client_secret
    YT_PROJECT_ID: {{ env_data.youtube_project_id }}
    YT_REFRESH_TOKEN: __vault__::secret-{{ business_unit }}/{{ app }}/{{ env_data.vault_env_path }}/youtube-credentials>data>refresh_token
