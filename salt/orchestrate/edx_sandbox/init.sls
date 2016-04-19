ensure_instance_profile_exists_for_edx_sandbox_ami:
  boto_iam_role.present:
    - name: edx-sandbox-ami-instance-role

deploy_logging_cloud_map:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/edx-sandbox-ami-map.yml
        parallel: True
