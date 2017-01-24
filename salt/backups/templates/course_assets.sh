#!/bin/bash
set -e

{% set backupdir = '/mnt/efs/{}'.format(settings.get('directory', 'course_assets')) %}

sudo mkdir -p /mnt/efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).{{ settings.efs_id }}.efs.us-east-1.amazonaws.com:/ /mnt/efs

PASSPHRASE={{ settings.duplicity_passphrase }} /usr/bin/duplicity \
          --s3-use-server-side-encryption {{ backupdir }} \
          --allow-source-mismatch \
          s3+http://odl-operations-backups/{{ settings.get('directory', 'course_assets') }}/

sudo umount /mnt/efs
