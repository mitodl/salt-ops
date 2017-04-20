#!/bin/bash
set -e

{% set backup_subdir = settings.get('directory', 'consul') %}
{% set backupdir = '/backups/{}'.format(backup_subdir) %}
mkdir -p {{ backupdir }}
SNAPFILE=`aws s3 ls odl-operations-backups/{{ backup_subdir }}/ | sort | tail -n 1 | awk '{print $4}'`

aws s3 cp s3://odl-operations-backups/{{ backup_subdir }}/$SNAPFILE  /{{ backupdir }}/$SNAPFILE

/usr/local/bin/consul snapshot inspect {{ backupdir }}/$SNAPFILE
/usr/local/bin/consul snapshot restore -token={{ settings.acl_token }} {{ backupdir }}/$SNAPFILE

rm {{ backupdir }}/$SNAPFILE
