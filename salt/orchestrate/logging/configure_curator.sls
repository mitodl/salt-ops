# Elasticsearch Curator is used for elasticsearch snapshots
install_elasticsearch_curator:
  pip.installed:
    - name: elasticsearch-curator
    - require:
      - salt: build_logging_nodes

put_elasticsearch_snapshot_config:
  http.query:
    - name: http://elasticsearch.service.consul:9200/_snapshot/s3_repository/
    - data: '
      {
      	"type": "s3",
  		"name": "elasticsearch_snapshot-%Y%m%d%H%M%S",
  		"wait_for_completion": true,
  		"settings": {
    		"bucket": "mitx-elasticsearch-backups"
  			}
		}'
	- method: PUT
	- status: 200

copy_elasticsearch_snapshot_config:
  file.managed:
    - name: /etc/elasticsearch/elasticsearch_snapshot.yml
    - source: salt://orchestrate/logging/elasicsearch_snapshot.yml

copy_elasticsearch_curator_config:
  file.managed:
    - name: /etc/elasticsearch/curator.yml
    - source: salt://orchestrate/logging/curator.yml

configure_snapshot_crontab:
  cron.present:
    - name: curator --config /etc/elasticsearch/curator.yml /etc/elasticsearch/elasicsearch_snapshot.yml
    - identifier: elasticsearch-snapshot-curator
    - minute: 00
    - hour: 05
