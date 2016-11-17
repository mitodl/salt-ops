#!/bin/bash

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mysql')) %}
mkdir -p {{ backupdir }}

/usr/bin/mysqldump --host {{ settings.host }} \
                   --port {{ settings.get('port', 3306) }} \
                   --user {{ settings.username }} \
                   --password {{ settings.password }} \
                   --add-drop-database --add-drop-table \
                   --single-transaction \
                   --result-file {{ backupdir }}/{{ settings.database }}.dump \
                   {{ settings.database }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          --s3-use-server-side-encryption {{ backupdir }} \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'mysql') }}/
