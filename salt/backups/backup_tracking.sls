{% set edx_tracking_local_folder = '/edx/var/log/tracking' %}
{% set instance_id = salt.grains.get('id') %}
{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set edx_tracking_bucket = 'odl-{}-tracking-backup'.format(business_unit) %}
{% set aws_creds = salt.pillar.get('edx:tracking_backups:aws_creds') %}

tar_tracking_data:
  cmd.run:
    - name: 'tar -czf edx_tracking_{{ instance_id }}.tgz *'
    - cwd: {{ edx_tracking_local_folder }}
    - creates: {{ edx_tracking_local_folder }}/edx_tracking_{{ instance_id }}.tgz

upload_tar_to_s3:
  module.run:
    - name: s3.put
    - bucket: {{ edx_tracking_bucket }}
    - path: {{ instance_id }}.tgz
    - local_file: {{ edx_tracking_local_folder }}/edx_tracking_{{ instance_id }}.tgz
    - key: {{ aws_creds.secret_key }}
    - keyid: {{ aws_creds.access_key}}

tracking_data_uploaded:
  file.touch:
    - name: {{ edx_tracking_local_folder }}/tracking_uploaded.txt
