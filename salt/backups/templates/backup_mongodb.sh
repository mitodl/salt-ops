#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mongodb')) %}
{% set cachedir = '/backups/.cache/{}'.format(settings.get('directory', 'mongodb')) %}
mkdir -p {{ backupdir }}
mkdir -p {{ cachedir }}

/usr/bin/mongodump --host {{ settings.host }} \
                   --port {{ settings.get('port', 27017) }} \
                   --password {{ settings.password }} --username admin \
                   --authenticationDatabase admin \
                   --out {{ backupdir }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          --s3-use-server-side-encryption {{ backupdir }} \
          --archive-dir {{ cachedir }} \
          --full-if-older-than 1W \
          --allow-source-mismatch --tempdir /backups/tmp/ \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'mongodb') }}/

rm -rf {{ backupdir }}
