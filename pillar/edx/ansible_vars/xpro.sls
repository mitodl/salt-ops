{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set bucket_prefix = env_data.secret_backends.aws.bucket_prefix %}

edx:
  ansible_vars:
    EDXAPP_SESSION_COOKIE_DOMAIN: .mitx.mit.edu
    EDXAPP_SESSION_COOKIE_NAME: {{ environment }}-{{ purpose }}-session
    EDXAPP_COMMENTS_SERVICE_URL: "http://localhost:4567"
    EDXAPP_COMMENTS_SERVICE_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/global/forum-api-key>data>value
    # Video Pipeline Settings
    EDXAPP_VIDEO_UPLOAD_PIPELINE:
      BUCKET: {{ bucket_prefix }}-edx-video-{{ environment }}
      ROOT_PATH: 'ingest/'
    EDXAPP_VIDEO_CDN_URLS:
      EXAMPLE_COUNTRY_CODE: "http://example.com/edx/video?s3_url="
    EDXAPP_LMS_ENV_EXTRA:
      THIRD_PARTY_AUTH_BACKENDS: ["social_auth_mitxpro.backends.MITxProOAuth2"]
      JWT_AUTH:
        JWT_ISSUER: 'OAUTH_OIDC_ISSUER'
        JWT_AUDIENCE: '{{ business_unit }}-{{ environment }}-key'
        JWT_SECRET_KEY: __vault__:gen_if_missing:secret-{{ business_unit }}/{{ environment }}/jwt-secret-key>data>value
        JWT_SIGNING_ALGORITHM: 'RS512'
        JWT_PRIVATE_SIGNING_JWK: __vault__::secret-{{ business_unit }}/{{ environment }}/jwt-signing-jwk/private-key>data>value
        JWT_PUBLIC_SIGNING_JWK_SET: __vault__::secret-{{ business_unit }}/{{ environment }}/jwt-signing-jwk/public-key>data>value
      FEATURES:
        ENABLE_VIDEO_UPLOAD_PIPELINE: True
        ENABLE_COMBINED_LOGIN_REGISTRATION: True
        ENABLE_OAUTH2_PROVIDER: True
        ENABLE_THIRD_PARTY_AUTH: True
        ALLOW_PUBLIC_ACCOUNT_CREATION: True
    EDXAPP_LMS_AUTH_EXTRA:
      SOCIAL_AUTH_OAUTH_SECRETS:
        mitxpro-oauth2: __vault__::secret-{{ business_unit }}/{{ environment }}/xpro-app-oauth2-client-secret>data>value
    EDXAPP_CMS_ENV_EXTRA:
      DISABLE_STUDIO_SSO_OVER_LMS: True
      FEATURES:
        ENABLE_VIDEO_UPLOAD_PIPELINE: True
