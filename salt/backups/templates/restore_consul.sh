#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'consul')) %}
mkdir -p {{ backupdir }}
SNAPFILE=`aws s3 ls odl-operations-backups/{{ backupdir }}/ | sort | tail -n 1 | awk '{print $4}'`

aws s3 cp s3+http://odl-operations-backups/{{ settings.get('directory', 'consul') }}/$SNAPFILE  /{{ backupdir }}/$SNAPFILE

/usr/local/bin/consul snapshot save -stale -token={{ settings.acl_token }} {{ backupdir }}/$SNAPFILE

rm {{ backupdir }}/$SNAPFILE
