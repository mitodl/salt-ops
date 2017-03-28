#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mongodb')) %}
{% set cacehdir = '/backups/.cache/{}'.format(settings.get('directory', 'mongodb')) %}
mkdir -p {{ backupdir }}

/usr/bin/mongodump --host {{ settings.host }} \
                   --port {{ settings.get('port', 27017) }} \
                   --password {{ settings.password }} --username admin \
                   --authenticationDatabase admin \
                   --out {{ backupdir }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          --s3-use-server-side-encryption {{ backupdir }} \
          --s3-use-ia \
          --archive-dir {{ cachedir }} \
          --full-if-older-than 1W \
          --allow-source-mismatch --tempdir /backups \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'mongodb') }}/

rm -rf {{ backupdir }}
