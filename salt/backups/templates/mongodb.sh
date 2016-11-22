#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mongodb')) %}
mkdir -p {{ backupdir }}

/usr/bin/mongodump --host {{ settings.host }} \
                   --port {{ settings.get('port', 27017) }} \
                   --password {{ settings.password }} --username admin \
                   --authenticationDatabase admin \
                   --out {{ backupdir }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          --s3-use-server-side-encryption {{ backupdir }} \
          --allow-source-mismatch \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'mongodb') }}/

rm -rf {{ backupdir }}
