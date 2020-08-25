{% set edx_tracking_local_folder = '/edx/var/log/tracking' %}
{% set instance_id = salt.grains.get('id') %}
{% set business_unit = salt.grains.get('business_unit', 'residential') %}
{% set edx_tracking_bucket = 'odl-{}-tracking-backup'.format(business_unit) %}
{% set aws_creds = salt.pillar.get('edx:tracking_backups:aws_creds') %}
{% set archive_name = 'edx_tracking_' ~ instance_id ~ '-' ~ salt.system.get_system_date_time().split(' ')[0] ~ '.tgz' %}

tar_tracking_data:
  cmd.run:
    - name: 'tar -czf {{ archive_name }} *'
    - cwd: {{ edx_tracking_local_folder }}
    - creates: {{ edx_tracking_local_folder }}/{{ archive_name }}

upload_tar_to_s3:
  module.run:
    - name: s3.put
    - bucket: {{ edx_tracking_bucket }}
    - path: {{ instance_id }}.tgz
    - local_file: {{ edx_tracking_local_folder }}/{{ archive_name }}
    - key: {{ aws_creds.secret_key }}
    - keyid: {{ aws_creds.access_key}}
