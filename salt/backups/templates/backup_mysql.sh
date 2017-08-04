#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mysql')) %}
{% set cachedir = '/backups/.cache/{}'.format(settings.get('directory', 'mysql')) %}
mkdir -p {{ backupdir }}
mkdir -p {{ cachedir }}

cd /backups/

/usr/bin/mydumper --host {{ settings.host }} \
                  --port {{ settings.get('port', 3306) }} \
                  --user {{ settings.username }} \
                  --password={{ settings.password }} \
                  --database {{ settings.database }} \
                  --outputdir {{ backupdir }} \
                  --threads {{ settings.get('threads', 4) }} \
                  --compress-protocol \
                  --logfile /backups/{{ settings.database }}-dump-log.txt

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          --s3-use-server-side-encryption {{ backupdir }} \
          --archive-dir {{ cachedir }} --asynchronous-upload \
          --full-if-older-than 1W --s3-use-multiprocessing \
          --allow-source-mismatch --tempdir /backups/tmp/ \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'mysql') }}

rm -rf {{ backupdir }}
