{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'operations') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set VPC_NAME = env_data.vpc_name %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}
{% set launch_date = salt.status.time(format="%Y-%m-%d") %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|map(attribute='id')|list %}

ensure_backup_bucket_exists:
  boto_s3_bucket.present:
    - Bucket: odl-operations-backups
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - Tagging:
        OU: operations
        business_unit: operations
        Department: operations
        Environment: operations

ensure_instance_profile_exists_for_backups:
  boto_iam_role.present:
    - name: backups-instance-role
    # - delete_policies: False
    # - policies:
    #     operations-backups-policy:
    #       Statement:
    #         - Action:
    #             - s3:*
    #           Effect: Allow
    #           Resource:
    #             - arn:aws:s3:::odl-operations-backups
    #             - arn:aws:s3:::odl-operations-backups/*
    - require:
        - boto_s3_bucket: ensure_backup_bucket_exists

load_backup_host_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/operations_backup_host.conf
    - source: salt://orchestrate/aws/cloud_profiles/backup_host.conf
    - template: jinja

deploy_backup_instance_to_{{ ENVIRONMENT }}:
  salt.function:
    - name: cloud.profile
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - backup_host
        - backup-{{ ENVIRONMENT }}
    - kwarg:
        vm_overrides:
          grains:
            environment: {{ ENVIRONMENT }}
          network_interfaces:
            - DeviceIndex: 0
              AssociatePublicIpAddress: True
              SubnetId: {{ subnet_ids[0] }}
              SecurityGroupId:
                - {{ salt.boto_secgroup.get_group_id(
                     'default', vpc_name=VPC_NAME) }}
                - {{ salt.boto_secgroup.get_group_id(
                     'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
    - require:
        - file: load_backup_host_cloud_profile
        - boto_iam_role: ensure_instance_profile_exists_for_backups

execute_enabled_backup_scripts:
  salt.state:
    - tgt: 'G@roles:backups and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - sls:
        - consul
        - consul.dns_proxy
        - backups.backup
    - require:
        - salt: deploy_backup_instance_to_{{ ENVIRONMENT }}

terminate_backup_instance_in_{{ ENVIRONMENT }}:
  salt.runner:
    - name: cloud.destroy
    - instances:
        - backup-{{ ENVIRONMENT }}
    - require:
        - salt: execute_enabled_backup_scripts

alert_devops_channel_on_failure:
  slack.post_message:
    - channel: '#devops'
    - from_name: saltbot
    - message: 'The scheduled backup for operations services has failed.'
    - api_key: {{ slack_api_token }}
    - onfail:
        - salt: execute_enabled_backup_scripts

alert_devops_channel_on_success:
  slack.post_message:
    - channel: '#devops'
    - from_name: saltbot
    - message: 'The scheduled backup for operations services has succeeded.'
    - api_key: {{ slack_api_token }}
    - require:
        - salt: execute_enabled_backup_scripts
        - salt: terminate_backup_instance_in_{{ ENVIRONMENT }}
