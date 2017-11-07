{% set edx_tracking_bucket = 'odl-residential-tracking-data' %}
{% set edx_tracking_bucket_creds = salt.vault.read('aws-mitx/creds/read-write-{bucket}'.format(bucket=edx_tracking_bucket)) %}
{% set edx_tracking_local_folder = '/edx/var/log/tracking' %}
{% set instance_id = salt.environ.get('MINION_ID') %}

tar_tracking_data:
  cmd.run:
    - name: 'tar -czf edx_tracking_{{ instance_id }}.tgz *'
    - cwd: {{ edx_tracking_local_folder }}

upload_tar_to_s3:
  module.run:
    - name: s3.put
    - bucket: {{ edx_tracking_bucket }}
    - path: 'retired-instance-logs'
    - keyid: {{ edx_tracking_bucket_creds.data.access_key }}
    - key: {{ edx_tracking_bucket_creds.data.secret_key }}
    - local_file: {{ edx_tracking_local_folder }}/edx_tracking_{{ instance_id }}.tgz
