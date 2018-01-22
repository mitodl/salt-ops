#!jinja|yaml|gpg
{% import_yaml "environment_settings.yml" as env_settings %}
{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set purpose_suffix = purpose.replace('-', '_') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set purpose_data = env_settings.environments[environment].purposes[purpose] %}
{% from "shared/edx/mitx.jinja" import edx with context %}
{% set mit_smtp = salt.vault.read('secret-operations/global/mit-smtp') %}
{% set mitx_wildcard_cert = salt.vault.read('secret-operations/global/mitx_wildcard_cert') %}

edx:
  {% if 'edx-worker' in salt.grains.get('roles') %}
  playbooks:
    - 'edx-east/worker.yml'
  {% endif %}
  mongodb:
    replset_name: rs0

  ssh_key: |
    {{ edx.ssh_key|indent(4) }}
  ssh_hosts:
    - name: github.com
      fingerprint: '9d:38:5b:83:a9:17:52:92:56:1a:5e:c4:d4:81:8e:0a:ca:51:a2:64:f1:74:20:11:2e:f8:8a:c3:a1:39:49:8f'
    - name: github.mit.edu
      fingerprint: 'aa:d2:e9:66:7e:46:77:d3:7d:d9:39:3f:f4:9f:17:a1:18:c1:87:8f:69:cb:8f:d0:db:10:b7:71:5e:ad:57:68'
  gitreload:
    gr_dir: /edx/app/gitreload
    gr_repo: github.com/mitodl/gitreload.git
    gr_version: master
    gr_log_dir: "/edx/var/log/gr"
    course_checkout: false
    gr_env:
      PORT: '8095'
      UPDATE_LMS: 'true'
      LOG_LEVEL: debug
      WORKERS: 1
      LOGFILE: "/edx/var/log/gr/gitreload.log"
      VIRTUAL_ENV: /edx/app/edxapp/venvs/edxapp
      EDX_PLATFORM: /edx/app/edxapp/edx-platform
      DJANGO_SETTINGS: aws
      REPODIR: {{ edx.edxapp_git_repo_dir }}
      NUM_THREADS: 3
      GITRELOAD_CONFIG: /edx/app/gitreload/gr.env.json
      LOG_FILE_PATH: /edx/var/log/gr/gitreload.log
    gr_repos: []
    basic_auth:
      location: /edx/app/nginx/gitreload.htpasswd
  smtp:
    relay_host: {{ mit_smtp.data.relay_host }}
    relay_username: {{ mit_smtp.data.relay_username }}
    relay_password: {{ mit_smtp.data.relay_password }}
    root_forward: {{ salt.sdb.get('sdb://consul/admin-email') }}
  efs_id: {{ edx.efs_id }}

  generate_tls_certificate: no
  tls_key: |
    {{ mitx_wildcard_cert.data.key|indent(4) }}
  tls_crt: |
    {{ mitx_wildcard_cert.data.value|indent(4) }}

  edxapp:
    GIT_REPO_DIR: {{ edx.edxapp_git_repo_dir }}
    THEME_NAME: 'mitx-theme'
    TLS_LOCATION: {{ edx.edxapp_tls_location_name }}
    TLS_KEY_NAME: {{ edx.edxapp_tls_key_name }}
    max_upload_size: {{ edx.edxapp_max_upload_size }} {# size in MB #}
    custom_theme:
      repo: 'https://github.com/mitodl/mitx-theme'
      branch: {{ purpose_data.versions.theme }}
