#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mysql')) %}
{% set cacehdir = '/backups/.cache/{}'.format(settings.get('directory', 'mysql')) %}
mkdir -p {{ backupdir }}

/usr/bin/mysqldump --host {{ settings.host }} \
                   --port {{ settings.get('port', 3306) }} \
                   --user {{ settings.username }} \
                   --password={{ settings.password }} --single-transaction \
                   --add-drop-database --add-drop-table \
                   --result-file {{ backupdir }}/{{ settings.database }}.dump \
                   {{ settings.database }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          --s3-use-server-side-encryption {{ backupdir }} \
          --s3-use-ia \
          --archive-dir {{ cachedir }} \
          --full-if-older-than 1W \
          --allow-source-mismatch --tempdir /backups \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'mysql') }}/

rm -rf {{ backupdir }}
