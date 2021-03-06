#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mongodb')) %}
{% set cachedir = '/backups/.cache/{}'.format(settings.get('directory', 'mongodb')) %}
mkdir -p {{ backupdir }}
mkdir -p {{ cachedir }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          remove-all-but-n-full 5 --archive-dir {{ cachedir }} \
          --asynchronous-upload --s3-use-multiprocessing \
          --tempdir /backups/tmp/ --force\
          s3+http://odl-operations-backups/{{ settings.get('directory', 'mongodb') }}/

/usr/bin/mongodump --host {{ settings.host }} \
                   --port {{ settings.get('port', 27017) }} \
                   --password={{ settings.password }} --username {{ settings.username }} \
                   --authenticationDatabase admin \
                   --oplog --out {{ backupdir }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          --s3-use-server-side-encryption {{ backupdir }} \
          --archive-dir {{ cachedir }} --asynchronous-upload \
          --full-if-older-than 1W --s3-use-multiprocessing \
          --allow-source-mismatch --tempdir /backups/tmp/ \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'mongodb') }}/

rm -rf {{ backupdir }}

curl --retry 3 {{ settings.healthcheck_url }}

salt-call event.fire_master '{"data": "Completed backup of MongoDB"}' backup/{{ ENVIRONMENT }}/{{ title }}/completed
