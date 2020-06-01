{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set MONGODB_REPLICASET = salt.pillar.get('mongodb:replset_name', 'rs0') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}

edx:
  ansible_vars:
    common_digicert_base_url: http://dl.cacerts.digicert.com/
    COMMON_ENABLE_AWS_ROLE: False
    COMMON_ENABLE_DATADOG: False
    EDXAPP_HERMES_ENABLED: False
    EDXAPP_EXTRA_MIDDLEWARE_CLASSES: [] # Worth keeping track of in case we need to take advantage of it
    EDXAPP_ENABLE_READING_FROM_MULTIPLE_HISTORY_TABLES: False
    EDXAPP_MONGO_AUTH_DB: ''
    EDXAPP_JWT_SIGNING_ALGORITHM: 'RS512'
    EDXAPP_JWT_PRIVATE_SIGNING_JWK: {{ salt.vault.read('secret-' ~  business_unit ~ '/' ~  environment ~ '/jwt-signing-jwk/private-key').data.value }}
    EDXAPP_JWT_PUBLIC_SIGNING_JWK_SET: {{ salt.vault.read('secret-' ~  business_unit ~ '/' ~  environment ~ '/jwt-signing-jwk/public-key').data.value }}
    EDXAPP_SOCIAL_AUTH_SAML_SP_PRIVATE_KEY: __vault__::secret-residential/{{ environment }}/{{ purpose }}/saml-sp-cert>data>key
    EDXAPP_SOCIAL_AUTH_SAML_SP_PUBLIC_CERT: __vault__::secret-residential/{{ environment }}/{{ purpose }}/saml-sp-cert>data>value
    EDXAPP_LMS_ENV_EXTRA:
      SECRET_KEY: __vault__:gen_if_missing:secret-residential/global/edxapp-lms-django-secret-key>data>value
      REMOTE_GRADEBOOK_USER: __vault__::secret-{{ business_unit }}/{{ environment }}/remote_gradebook>data>user
      REMOTE_GRADEBOOK_PASSWORD: __vault__::secret-{{ business_unit }}/{{ environment }}/remote_gradebook>data>password
      FEATURES:
        ENABLE_THIRD_PARTY_ONLY_AUTH: True
      MONGODB_LOG:
        db: gitlog_{{ purpose_suffix }}
        host: mongodb-master.service.consul
        user: __vault__:cache:mongodb-{{ environment }}/creds/gitlog-{{ purpose }}>data>username
        password: __vault__:cache:mongodb-{{ environment }}/creds/gitlog-{{ purpose }}>data>password
        replicaset: "{{ MONGODB_REPLICASET }}"
        readPreference: "nearest"
    EDXAPP_CMS_ENV_EXTRA:
      SECRET_KEY: __vault__:gen_if_missing:secret-residential/global/edxapp-lms-django-secret-key>data>value
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
      - name: git+https://github.com/edx/edx-zoom.git@37c323ae93265937bf60abb92657318efeec96c5#egg=edx-zoom
        extra_args: -e
      # MITx Residential XBlocks
      - name: edx-sga==0.10.0
      - name: rapid-response-xblock==0.0.6
      - name: git+https://github.com/mitodl/edx-git-auto-export.git@v0.2#egg=edx-git-auto-export
        extra_args: -e
      - name: git+https://github.com/Stanford-Online/xblock-in-video-quiz@release/v0.1.7#egg=xblock-in-video-quiz
        extra_args: -e
      - name: xblock-image-modal==0.4.2
      # Python client for Sentry
      - name: raven
      - name: git+https://github.com/raccoongang/xblock-pdf.git@8d63047c53bc8fdd84fa7b0ec577bb0a729c215f#egg=xblock-pdf
        extra_args: -e

    NGINX_SSL_CIPHERS: "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"

  dependencies:
    os_packages:
      - git
      - libmysqlclient-dev
      - mariadb-client-10.0
      - landscape-common
      - libssl-dev
      - python2.7
      - python2.7-dev
      - python3.5
      - python3.5-dev
      - python-pip
      - python3-pip
      - python-virtualenv
      - nfs-common
      - postfix

python_dependencies:
  python_libs:
    - virtualenv<20
    - pyopenssl
