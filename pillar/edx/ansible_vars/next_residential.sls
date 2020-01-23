{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}

edx:
  ansible_vars:
    EDXAPP_EXTRA_MIDDLEWARE_CLASSES: [] # Worth keeping track of in case we need to take advantage of it
    EDXAPP_ENABLE_READING_FROM_MULTIPLE_HISTORY_TABLES: False

    EDXAPP_PRIVATE_REQUIREMENTS:
      # For Harvard courses. Peer instruction XBlock.
      # edX comment in `configuration' repo at
      # https://github.com/edx/configuration/blob/e7433e03313ffc86a3cfd046c5178ec587841c19/playbooks/roles/edxapp/defaults/main.yml#L528
      # says:
      # "Need it from github until we can land https://github.com/ubc/ubcpi/pull/167 upstream."
      - name: git+https://github.com/edx/ubcpi.git@3c4b2cdc9f595ab8cdb436f559b56f36638313b6#egg=ubcpi-xblock
        extra_args: -e
      # Vector Drawing and ActiveTable XBlocks (Davidson)
      - name: git+https://github.com/open-craft/xblock-vectordraw.git@76976425356dfc7f13570f354c0c438db84c2840#egg=xblock-vectordraw==0.3.0
        extra_args: -e
      - name: git+https://github.com/open-craft/xblock-activetable.git@013003aa3ce28f0ae03b8227dc3a6daa4e19997d#egg=xblock-activetable
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

  dependencies:
    os_packages:
      - git
      - libmysqlclient-dev
      - mariadb-client-10.0
      - landscape-common
      - libssl-dev
      - python3.5
      - python3.5-dev
      - python-pip
      - python-virtualenv
      - nfs-common
      - postfix
      - memcached
