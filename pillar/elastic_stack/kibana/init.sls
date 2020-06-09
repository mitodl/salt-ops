{% set ENVIRONMENT = salt.grains.get('environment') %}

elastic_stack:
  kibana:
    config:
      {% if 'operations-qa' in ENVIRONMENT %}
      elasticsearch.hosts:
        - https://nearest-elasticsearch.query.consul:9200
      elasticsearch.username: __vault__::secret-operations/{{ ENVIRONMENT }}/xpack/elasticsearch/kibana>data>es_kibana_username
      elasticsearch.password: __vault__::secret-operations/{{ ENVIRONMENT }}/xpack/elasticsearch/kibana>data>es_kibana_password
      xpack.security.encryptionKey: __vault__::secret-operations/{{ ENVIRONMENT }}/xpack/elasticsearch/kibana>data>es_kibana_encryption_key
      {% else %}
      elasticsearch.hosts:
        - http://nearest-elasticsearch.query.consul:9200
      {% endif %}
      elasticsearch.requestTimeout: 120000
      logging.dest: /var/log/kibana.log
      elasticsearch.ssl.verificationMode: "none"

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
