elastic_stack:
  kibana:
    config:
      elasticsearch.url: http://nearest-elasticsearch.query.consul:9200
      elasticsearch.requestTimeout: 120000
      logging.dest: /var/log/kibana.log

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
