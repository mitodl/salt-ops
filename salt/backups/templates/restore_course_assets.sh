#!/bin/bash
set -e

{% set backupdir = '/mnt/efs/{}'.format(settings.get('directory', 'course_assets')) %}

mkdir -p /mnt/efs
mountpoint /mnt/efs || mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).{{ settings.efs_id }}.efs.us-east-1.amazonaws.com:/ /mnt/efs

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity restore \
          --s3-use-server-side-encryption s3+http://odl-operations-backups/{{ settings.get('directory', 'course_assets') }}/ \
          --force --tempdir /backups {{ backupdir }}/
