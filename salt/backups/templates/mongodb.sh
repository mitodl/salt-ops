#!/bin/bash

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mongodb')) %}
mkdir -p {{ backupdir }}

/usr/bin/mongodump --host {{ settings.host }} \
                   --port {{ settings.get('port', 27017) }} \
                   --username admin --password {{ settings.password }} \
                   --authenticationDatabase admin \
                   --out {{ backupdir }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          --s3-use-server-side-encryption {{ backupdir }} \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'mongodb') }}/
