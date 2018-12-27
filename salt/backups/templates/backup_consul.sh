#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'consul')) %}
mkdir -p {{ backupdir }}
SNAPFILE={{ backupdir }}/consul_snapshot-`date +%Y-%m-%d_%H-%M-%S`.snap

/usr/local/bin/consul snapshot save -stale -token={{ settings.acl_token }} $SNAPFILE

aws s3 cp $SNAPFILE s3://odl-operations-backups/{{ settings.get('directory', 'consul') }}/

rm $SNAPFILE

curl --retry 3 {{ setting.healthcheck_url }}

salt-call event.fire_master '{"data": "Completed backup of Consul"}' backup/{{ ENVIRONMENT }}/{{ title }}/completed
