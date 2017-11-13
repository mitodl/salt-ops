{% set edx_tracking_bucket = 'odl-residential-tracking-backup' %}
{% set edx_tracking_local_folder = '/edx/var/log/tracking' %}
{% set instance_id = salt.grains.get('id') %}

ensure_tracking_bucket_exists:
  boto_s3_bucket.present:
    - Bucket: {{ edx_tracking_bucket }}
    - region: us-east-1

ensure_instance_profile_exists_for_tracking:
  boto_iam_role.present:
    - name: edx-instance-role
    - delete_policies: False
    - policies:
        edx-old-tracking-logs-policy:
          Statement:
            - Action:
                - s3:GetObject
                - s3:ListAllMyBuckets
                - s3:ListBucket
                - s3:ListObjects
                - s3:PutObject
              Effect: Allow
              Resource:
                - arn:aws:s3:::{{ edx_tracking_bucket }}
                - arn:aws:s3:::{{ edx_tracking_bucket }}/*
    - require:
        - boto_s3_bucket: ensure_tracking_bucket_exists

tar_tracking_data:
  cmd.run:
    - name: 'tar -czf edx_tracking_{{ instance_id }}.tgz *'
    - cwd: {{ edx_tracking_local_folder }}
    - creates: {{ edx_tracking_local_folder }}/edx_tracking_{{ instance_id }}.tgz

upload_tar_to_s3:
  module.run:
    - name: s3.put
    - bucket: {{ edx_tracking_bucket }}
    - path: 'retired-instance-logs'
    - local_file: {{ edx_tracking_local_folder }}/edx_tracking_{{ instance_id }}.tgz
