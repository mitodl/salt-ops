{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}

edx:
  ansible_vars:
    EDXAPP_EXTRA_MIDDLEWARE_CLASSES: [] # Worth keeping track of in case we need to take advantage of it
    NGINX_HTTPS_REDIRECT_STRATEGY: forward_for_proto
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
    EDXAPP_CMS_ENV_EXTRA:
      ADDL_INSTALLED_APPS:
        - ubcpi
        - git_auto_export
