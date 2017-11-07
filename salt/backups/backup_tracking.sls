{% set edx_tracking_bucket = 'odl-residential-tracking-backup' %}
{% set edx_tracking_bucket_backup_key = salt.pillar.get('backups:mitx_residential_tracking:aws_key') %}
{% set edx_tracking_bucket_backup_keyid = salt.pillar.get('backups:mitx_residential_tracking:aws_keyid') %}
{% set edx_tracking_local_folder = '/edx/var/log/tracking' %}
{% set instance_id = salt.grains.get('id') %}

tar_tracking_data:
  cmd.run:
    - name: 'tar -czf edx_tracking_{{ instance_id }}.tgz *'
    - cwd: {{ edx_tracking_local_folder }}
    - creates: edx_tracking_{{ instance_id }}.tgz

upload_tar_to_s3:
  module.run:
    - name: s3.put
    - bucket: {{ edx_tracking_bucket }}
    - path: 'retired-instance-logs'
    - keyid: {{ edx_tracking_bucket_backup_keyid }}
    - key: {{ edx_tracking_bucket_backup_key }}
    - local_file: {{ edx_tracking_local_folder }}/edx_tracking_{{ instance_id }}.tgz
