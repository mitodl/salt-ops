{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set purpose = salt.grains.get('purpose', 'xqwatcher') %}
{% set purpose_data = env_settings.environments[environment].purposes[purpose] %}
{% set xqwatcher_venv_base = '/edx/app/xqwatcher/venvs' %}

edx:
  xqwatcher:
    logconfig:
      version: 1
      disable_existing_loggers: False
      formatters:
        default:
          format: '%(asctime)s - %(filename)s:%(lineno)d -- %(funcName)s [%(levelname)s]: %(message)s'
      handlers:
        console:
          class: logging.StreamHandler
          formatter: default
          level: DEBUG
        rotatingfile:
          class: logging.handlers.RotatingFileHandler
          formatter: default
          level: DEBUG
          filename: /edx/var/log/xqwatcher/xqwatcher.log
          maxBytes: 10485760
      loggers:
        "":
          level: DEBUG
          handlers:
            - rotatingfile
            - console
  config:
    repo: {{ purpose_data.versions.edx_config_repo }}
    branch: {{ purpose_data.versions.edx_config_version }}
  playbooks:
    - 'edx-east/xqwatcher.yml'
  ansible_vars:
    XQWATCHER_VERSION: {{ purpose_data.versions.xqwatcher }}
    XQWATCHER_GIT_IDENTITY: "__vault__::secret-residential/global/xqueue_watcher_git_ssh>data>value"
    XQWATCHER_CONFIG:
      POLL_TIME: 10
      REQUESTS_TIMEOUT: 10
      POLL_INTERVAL: 10
      FOLLOW_CLIENT_REDIRECTS: True
    XQWATCHER_REPOS:
      - PROTOCOL: "https"
        DOMAIN: "github.com"
        PATH: "mitodl"
        REPO: "xqueue-watcher.git"
        VERSION: "{{ purpose_data.versions.xqwatcher }}"
        DESTINATION: "/edx/app/xqwatcher/src"
        SSH_KEY: "__vault__::secret-residential/global/xqueue_watcher_git_ssh>data>value"
