#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mongodb')) %}
{% set cachedir = '/backups/.cache/{}'.format(settings.get('directory', 'mongodb')) %}
mkdir -p {{ backupdir }}
mkdir -p {{ cachedir }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity restore\
          --s3-use-server-side-encryption s3+http://odl-operations-backups/{{ settings.get('directory', 'mongodb') }} \
          --archive-dir {{ cachedir }} --s3-use-multiprocessing \
          --force --tempdir /backups/tmp/ {{ backupdir }}

{% for target_db, source_db in settings.db_map.items() %}
/usr/bin/mongorestore --host {{ settings.host }} \
                      --port {{ settings.get('port', 27017) }} \
                      --password {{ settings.password }} --username {{ settings.username }} \
                      --authenticationDatabase admin \
                      --db {{ target_db }} \
                      --drop {{ backupdir }}/{{ source_db }}
{% endfor %}
rm -rf {{ backupdir }}
