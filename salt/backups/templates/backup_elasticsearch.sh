#!/bin/bash
set -e

SNAPFILE=elasticsearch_snapshot-`date +%Y-%m-%d_%H-%M-%S`
curl -XPUT http://elasticsearch.service.consul:9200/_snapshot/{{ settings.snapshot_repository_name }}/$SNAPFILE?wait_for_completion=true

curl --retry 3 {{ settings.healthcheck_url }}

salt-call event.fire_master '{"data": "Completed backup of Elasticsearch"}' backup/{{ ENVIRONMENT }}/{{ title }}/completed
