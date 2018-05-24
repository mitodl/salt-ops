{% set mailgun_apps = {
    'micromasters': 'mailgun-eng',
    'discussions': 'mailgun-eng'} %}
{% set slack_webhook_url = '__vault__::secret-operations/global/slack-odl/slack_webhook_url>data>value' %}

elasticsearch:
  lookup:
    elastic_stack: True
    pkgs:
      - apt-transport-https
      - nginx
      - python-openssl

kibana:
  lookup:
    nginx_config:
      server.name: logs.odl.mit.edu
      server.ssl.enabled: true
      server.ssl.certificate: /etc/salt/ssl/certs/kibana.odl.mit.edu.crt
      server.ssl.key: /etc/salt/ssl/certs/kibana.odl.mit.edu.key
    nginx_extra_config_list:
      - ssl_client_certificate /etc/salt/ssl/certs/mitca.pem;
      - ssl_verify_client on;
      - set $authorized "no";
      - if ($ssl_client_s_dn ~ "/emailAddress=(tmacey|pdpinch|shaidar|ichuang|gsidebo|mkdavies|gschneel|mattbert|nlevesq|ferdial|maxliu)@MIT.EDU") { set $authorized "yes"; }
      - if ($authorized !~ "yes") { return 403; }
    nginx_extra_files:
      - name: mitca
        path: /etc/salt/ssl/certs/mitca.pem
        contents: __vault__::secret-operations/global/mitca_ssl_cert>data>value
  ssl:
    cert_source: __vault__::secret-operations/global/odl_wildcard_cert>data>value
    key_source: __vault__::secret-operations/global/odl_wildcard_cert>data>key

beacons:
  service:
    - services:
        kibana:
          onchangeonly: True
          interval: 30
        nginx:
          onchangeonly: True
          interval: 30
        elastalert:
          onchangeonly: True
          interval: 30
    - disable_during_state_run: True
