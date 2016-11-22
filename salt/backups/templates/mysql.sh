#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mysql')) %}
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
          --allow-source-mismatch \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'mysql') }}/

rm -rf {{ backupdir }}
