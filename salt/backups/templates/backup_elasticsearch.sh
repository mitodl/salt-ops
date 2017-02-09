#!/bin/bash
set -e

SNAPFILE=elasticsearch_snapshot-`date +%Y-%m-%d_%H-%M-%S`
curl -XPUT http://elasticsearch.service.consul:9200/_snapshot/{{ settings.snapshot_repository_name }}/$SNAPFILE?wait_for_completion=true
