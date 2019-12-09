{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}

edx:
  ansible_vars:
    EDXAPP_EXTRA_MIDDLEWARE_CLASSES: [] # Worth keeping track of in case we need to take advantage of it
    EDXAPP_LMS_ENV_EXTRA:
      FEATURES:
        AUTH_USE_CAS: False
    EDXAPP_CMS_ENV_EXTRA:
      FEATURES:
        AUTH_USE_CAS: False
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
        - name: git+https://github.com/raccoongang/xblock-pdf.git@8d63047c53bc8fdd84fa7b0ec577bb0a729c215f#egg=xblock-pdf
          extra_args: -e
