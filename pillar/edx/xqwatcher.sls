{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set env_data = env_settings.environments[environment] %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
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
        syslog:
          class: logging.handlers.SysLogHandler
          formatter: default
          level: INFO
          address: /dev/log
      loggers:
        "":
          level: INFO
          handlers:
            - syslog
            - console
  config:
    repo: {{ purpose_data.versions.edx_config_repo }}
    branch: {{ purpose_data.versions.edx_config_version }}
  playbooks:
    - 'edx-east/xqwatcher.yml'
  ansible_vars:
    XQWATCHER_VERSION: {{ purpose_data.versions.xqwatcher_version }}
    XQWATCHER_GIT_IDENTITY: __vault__::secret-residential/global/xqueue_watcher_git_ssh>data>value
    XQWATCHER_CONFIG:
      POLL_TIME: 10
      REQUESTS_TIMEOUT: 1.5
    XQWATCHER_REPOS:
      - PROTOCOL: "https"
        DOMAIN: "github.com"
        PATH: "mitodl"
        REPO: "xqueue-watcher.git"
        VERSION: "{{ purpose_data.versions.xqwatcher_version }}"
        DESTINATION: "/edx/app/xqwatcher/src"
        SSH_KEY: __vault__::secret-residential/global/xqueue_watcher_git_ssh>data>value
