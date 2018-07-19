elasticsearch:
  lookup:
    elastic_stack: True
    pkgs:
      - apt-transport-https
      - nginx
      - python-openssl

kibana:
  lookup:
    config:
      elasticsearch.url: http://nearest-elasticsearch.query.consul:9200
      logging.dest: /var/log/kibana.log
    nginx_config:
      server_name: logs.odl.mit.edu
      cert_path: /etc/salt/ssl/certs/kibana.odl.mit.edu.crt
      key_path: /etc/salt/ssl/certs/kibana.odl.mit.edu.key
    nginx_extra_config_list:
      - ssl_client_certificate /etc/salt/ssl/certs/mitca.pem;
      - ssl_verify_client on;
      - set $authorized "no";
      - if ($ssl_client_s_dn ~ "/emailAddress=(tmacey|pdpinch|shaidar|ichuang|gsidebo|mkdavies|gschneel|mattbert|nlevesq|ferdial|maxliu|annagav)@MIT.EDU") { set $authorized "yes"; }
      - if ($authorized !~ "yes") { return 403; }
    nginx_extra_files:
      - name: mitca
        path: /etc/salt/ssl/certs/mitca.pem
        contents: __vault__::secret-operations/global/mitca_ssl_cert>data>value
    ssl:
      cert_contents: __vault__::secret-operations/global/odl_wildcard_cert>data>value
      key_contents: __vault__::secret-operations/global/odl_wildcard_cert>data>key

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
