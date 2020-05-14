#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mysql')) %}
{% set cachedir = '/backups/.cache/{}'.format(settings.get('directory', 'mysql')) %}
mkdir -p {{ backupdir }}
mkdir -p {{ cachedir }}

cd /backups/

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          remove-all-but-n-full 5 --archive-dir {{ cachedir }} \
          --asynchronous-upload --s3-use-multiprocessing \
          --tempdir /backups/tmp/ --force\
          s3+http://odl-operations-backups/{{ settings.get('directory', 'mysql') }}

/usr/bin/mydumper --host {{ settings.host }} \
                  --port {{ settings.get('port', 3306) }} \
                  --user {{ settings.username }} \
                  --password={{ settings.password }} \
                  --database {{ settings.database }} \
                  --outputdir {{ backupdir }} \
                  --threads {{ settings.get('threads', 4) }} \
                  --compress-protocol --less-locking \
                  --routines --triggers --rows 1000000 \
                  --logfile /backups/{{ settings.database }}-dump-log.txt

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          --s3-use-server-side-encryption {{ backupdir }} \
          --archive-dir {{ cachedir }} --asynchronous-upload \
          --full-if-older-than 1W --s3-use-multiprocessing \
          --allow-source-mismatch --tempdir /backups/tmp/ \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'mysql') }}

rm -rf {{ backupdir }}

curl --retry 3 {{ settings.healthcheck_url }}

salt-call event.fire_master '{"data": "Completed backup of MySQL"}' backup/{{ ENVIRONMENT }}/{{ title }}/completed
