#!/bin/bash
set -e

{% set backupdir = '/backups/{}'.format(settings.get('directory', 'mysql')) %}
{% set cachedir = '/backups/.cache/{}'.format(settings.get('directory', 'mysql')) %}
mkdir -p {{ backupdir }}

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity restore \
          --s3-use-server-side-encryption s3+http://odl-operations-backups/{{ settings.get('directory', 'mysql') }}/ \
          {{ settings.database }}/ --archive-dir {{ cachedir }} \
          --force --tempdir /backups/tmp/ {{ backupdir }}/{{ settings.database }}

/usr/bin/mysql --host {{ settings.host }} \
               --port {{ settings.get('port', 3306) }} \
               --user {{ settings.username }} \
               --password={{ settings.password }} \
               --database={{ settings.database }} \
               < {{ backupdir }}/{{ settings.database }}.dump
