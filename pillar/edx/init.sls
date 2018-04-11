#!jinja|yaml
{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set purpose_data = env_settings.environments[environment].purposes[purpose] %}
{% set ssh_key = salt.vault.read('secret-residential/global/mitx-ssh-key').data.value %}
{% set mitx_wildcard_cert = salt.vault.read('secret-operations/global/mitx_wildcard_cert') %}

edx:
  mongodb:
    replset_name: rs0
  ssh_key: |
    {{ ssh_key|indent(4) }}
  ssh_hosts:
    - name: github.com
      fingerprint: '9d:38:5b:83:a9:17:52:92:56:1a:5e:c4:d4:81:8e:0a:ca:51:a2:64:f1:74:20:11:2e:f8:8a:c3:a1:39:49:8f'
    - name: github.mit.edu
      fingerprint: 'aa:d2:e9:66:7e:46:77:d3:7d:d9:39:3f:f4:9f:17:a1:18:c1:87:8f:69:cb:8f:d0:db:10:b7:71:5e:ad:57:68'
  generate_tls_certificate: no
  tls_key: |
    {{ mitx_wildcard_cert.data.key|indent(4) }}
  tls_crt: |
    {{ mitx_wildcard_cert.data.value|indent(4) }}

  edxapp:
    THEME_NAME: 'mitx-theme'
    TLS_LOCATION: '/etc/pki/tls/certs'
    TLS_KEY_NAME: 'edx-ssl-cert'
    max_upload_size: 20
    custom_theme:
      repo: 'https://github.com/mitodl/mitx-theme'
      branch: {{ purpose_data.versions.theme }}
