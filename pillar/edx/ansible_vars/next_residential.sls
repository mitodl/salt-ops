{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}

edx:
  ansible_vars:
    EDXAPP_EXTRA_MIDDLEWARE_CLASSES: [] # Worth keeping track of in case we need to take advantage of it
    EDXAPP_SESSION_COOKIE_DOMAIN: .mitx.mit.edu
    EDXAPP_SESSION_COOKIE_NAME: {{ environment }}-{{ purpose }}-session
    EDXAPP_CMS_AUTH_EXTRA:
      SECRET_KEY: __vault__:gen_if_missing:secret-residential/global/edxapp-lms-django-secret-key>data>value
    EDXAPP_LMS_ENV_EXTRA:
      FEATURES:
        AUTH_USE_CAS: True
        ALLOW_PUBLIC_ACCOUNT_CREATION: False
        SKIP_EMAIL_VALIDATION: True
        ENABLE_VIDEO_UPLOAD_PIPELINE: False
    EDXAPP_CMS_ENV_EXTRA:
      FEATURES:
        AUTH_USE_CAS: True
      ADDL_INSTALLED_APPS:
        - ubcpi
        - git_auto_export
        - imagemodal
    EDXAPP_PRIVATE_REQUIREMENTS:
        # For Harvard courses:
        # Peer instruction XBlock
        - name: ubcpi-xblock==0.6.4
        # Vector Drawing and ActiveTable XBlocks (Davidson)
        - name: git+https://github.com/open-craft/xblock-vectordraw.git@c57df9d98119fd2ca4cb31b9d16c27333cdc65ca#egg=xblock-vectordraw==0.2.1
          extra_args: -e
        - name: git+https://github.com/open-craft/xblock-activetable.git@e933d41bb86a8d50fb878787ca680165a092a6d5#egg=xblock-activetable
          extra_args: -e
       # MITx Residential XBlocks
        - name: edx-sga==0.8.2
        - name: rapid-response-xblock==0.0.5
        - name: git+https://github.com/mitodl/edx-git-auto-export.git@v0.1#egg=edx-git-auto-export
          extra_args: -e
        - name: git+https://github.com/Stanford-Online/xblock-in-video-quiz@release/v0.1.7#egg=xblock-in-video-quiz
          extra_args: -e
        - name: xblock-image-modal==0.4.2
        # Python client for Sentry
        - name: raven
