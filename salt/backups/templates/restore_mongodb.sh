#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mongodb')) %}
mkdir -p {{ backupdir }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity restore\
          --s3-use-server-side-encryption s3+http://odl-operations-backups/{{ settings.get('directory', 'mongodb') }}/ \
          --tempdir /backups {{ backupdir }}/

/usr/bin/mongorestore --host {{ settings.host }} \
                      --port {{ settings.get('port', 27017) }} \
                      --password {{ settings.password }} --username admin \
                      --authenticationDatabase admin \
                      {{ backupdir }}
