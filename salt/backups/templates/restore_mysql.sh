#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mysql')) %}
{% set cachedir = '/backups/.cache/{}'.format(settings.get('directory', 'mysql')) %}
mkdir -p {{ backupdir }}
mkdir -p {{ cachedir }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity restore \
          --s3-use-server-side-encryption s3+http://odl-operations-backups/{{ settings.get('directory', 'mysql') }} \
          --archive-dir {{ cachedir }} \
          --force --tempdir /backups/tmp/ {{ backupdir }}/

/usr/bin/myloader --host {{ settings.host }} \
                  --port {{ settings.get('port', 3306) }} \
                  --user {{ settings.username }} \
                  --password={{ settings.password }} \
                  --database={{ settings.restore_to }} \
                  --compress-protocol --overwrite-tables \
                  --source-db {{ settings.restore_from }} \
                  --directory {{ backupdir }} \
                  --threads {{ settings.get('threads', 4) }}
