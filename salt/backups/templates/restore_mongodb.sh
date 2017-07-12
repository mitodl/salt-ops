#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mongodb')) %}
{% set cachedir = '/backups/.cache/{}'.format(settings.get('directory', 'mongodb')) %}
mkdir -p {{ backupdir }}
mkdir -p {{ cachedir }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity restore\
          --s3-use-server-side-encryption s3+http://odl-operations-backups/{{ settings.get('directory', 'mongodb') }} \
          --archive-dir {{ cachedir }} \
          --force --tempdir /backups/tmp/ {{ backupdir }}

{% for key, value in mongodb.items() %}
/usr/bin/mongorestore --host {{ settings.host }} \
                      --port {{ settings.get('port', 27017) }} \
                      --password {{ settings.password }} --username admin \
                      --authenticationDatabase admin \
                      --db {{ value }} \
                      --drop {{ backupdir }}/{{ key }}
{% endfor %}
rm -rf {{ backupdir }}
