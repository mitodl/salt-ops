#!/bin/bash
set -e

{% set backupdir = '/mnt/efs/{}'.format(settings.get('directory', 'course_assets')) %}
{% set cachedir = '/mnt/efs/.cache/course_assets' %}

mkdir -p /mnt/efs
mountpoint /mnt/efs || mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).{{ settings.efs_id }}.efs.us-east-1.amazonaws.com:/ /mnt/efs

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          remove-all-but-n-full 5 --archive-dir {{ cachedir }} \
          --asynchronous-upload --s3-use-multiprocessing \
          --tempdir /backups/tmp/ \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'course_assets') }}/

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          --s3-use-server-side-encryption {{ backupdir }} \
          --archive-dir {{ cachedir }} --asynchronous-upload \
          --full-if-older-than 1W --s3-use-multiprocessing \
          --allow-source-mismatch --tempdir /backups/tmp/ \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'course_assets') }}/

curl --retry 3 {{ settings.healthcheck_url }}

salt-call event.fire_master '{"data": "Completed backup of MITx static assets"}' backup/{{ ENVIRONMENT }}/{{ title }}/completed
