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
    # Video Pipeline Settings
    EDXAPP_VIDEO_UPLOAD_PIPELINE:
      BUCKET: {{ bucket_prefix }}-edx-video-{{ environment }}
      ROOT_PATH: 'ingest/'
    EDXAPP_VIDEO_CDN_URLS:
      EXAMPLE_COUNTRY_CODE: "http://example.com/edx/video?s3_url="
    EDXAPP_LMS_ENV_EXTRA:
      FEATURES:
        ENABLE_VIDEO_UPLOAD_PIPELINE: True
    EDXAPP_CMS_ENV_EXTRA:
      FEATURES:
        ENABLE_VIDEO_UPLOAD_PIPELINE: True
