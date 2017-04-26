{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'mitx-rp') %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', 'Dogwood RP') %}
{% set VPC_RESOURCE_SUFFIX = salt.environ.get('VPC_RESOURCE_SUFFIX',
                                              VPC_NAME.lower() | replace(' ', '-')) %}
{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-{}'.format(VPC_RESOURCE_SUFFIX), 'public2-{}'.format(VPC_RESOURCE_SUFFIX), 'public3-{}'.format(VPC_RESOURCE_SUFFIX)])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}
{% set slack_api_token = salt.vault.read('secret-operations/global/slack/slack_api_token.data.value') %}
{% set backup_volume_name = 'odl-operations-backups-cache-{}'.format(ENVIRONMENT) %}

ensure_backup_bucket_exists:
  boto_s3_bucket.present:
    - Bucket: odl-operations-backups
    - Versioning:
        Status: Enabled
    - region: us-east-1

ensure_instance_profile_exists_for_backups:
  boto_iam_role.present:
    - name: backups-instance-role
    - delete_policies: False
    - policies:
        operations-backups-policy:
          Statement:
            - Action:
                - s3:*
              Effect: Allow
              Resource:
                - arn:aws:s3:::odl-operations-backups
                - arn:aws:s3:::odl-operations-backups/*
    - require:
        - boto_s3_bucket: ensure_backup_bucket_exists

load_backup_host_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/backup_host.conf
    - source: salt://orchestrate/aws/cloud_profiles/backup_host.conf

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
                     'salt_master-{}'.format(VPC_RESOURCE_SUFFIX), vpc_name=VPC_NAME) }}
                - {{ salt.boto_secgroup.get_group_id(
                     'edx-{}'.format(VPC_RESOURCE_SUFFIX), vpc_name=VPC_NAME) }}
    - require:
        - file: load_backup_host_cloud_profile
        - boto_iam_role: ensure_instance_profile_exists_for_backups

{# Duplicity requires an archive directory otherwise it will have to create it and download files
from s3 buckets when called. In order to accomodate that, we have an EBS volume that will be mounted
by the ephemeral instance that is destroyed once backups are complete. #}
{% set instance_id = salt.boto_ec2.find_instances('name=backups-{}'.format(ENVIRONMENT)) %}
{% if instance_id %}
attach_backup_volume:
  salt.function:
    - name: saltutil.runner
    - arg:
        - cloud.action
    - kwarg:
        func: ec2.attach_volume
        kwargs:
          instance_id: {{ instance_id }}
          volume_name: {{ backup_volume_name }}
          zone: us-east-1b
          size: 400

mount_backup_drive:
  salt.function:
    - tgt: 'G@roles:backups and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - mount.mounted
    - kwarg:
        name: /backups
        device: /dev/{{ salt.grains.get('ec2:block_device_mapping:ebs2') }}
        fstype: ext4
        mkmnt: True
        opts: 'relatime,user'

create_backup_directory:
  salt.function:
    - tgt: 'G@roles:backups and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - file.directory
    - kwargs:
        name: backups
        makedirs: True

execute_enabled_backup_scripts:
  salt.state:
    - tgt: 'G@roles:backups and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - sls:
        - consul
        - consul.dns_proxy
        - backups
    - require:
        - salt: deploy_backup_instance_to_{{ ENVIRONMENT }}
        - salt: mount_backup_drive

unmount_backup_drive:
  salt.function:
    - tgt: 'G@roles:backups and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: state.single
    - arg:
        - mount.unmounted
    - kwarg:
        name: /backups
        device: /dev/{{ salt.grains.get('ec2:block_device_mapping:ebs2') }}

detach_backup_volume:
  salt.function:
    - tgt: 'G@roles:backups and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: saltutil.runner
    - arg:
        - cloud.action
    - kwarg:
        func: ec2.detach_volume
        kwargs:
          volume_id:
          instance_id: {{ instance_id }}
          device: /dev/{{ salt.grains.get('ec2:block_device_mapping:ebs2') }}
    - require:
        - salt: unmount_backup_drive

terminate_backup_instance_in_{{ ENVIRONMENT }}:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
        - cloud.destroy
    - kwarg:
        instances:
          - backup-{{ ENVIRONMENT }}
    - require:
        - salt: execute_enabled_backup_scripts
        - salt: detach_backup_volume
{% endif %}

alert_devops_channel_on_failure:
  slack.post_message:
    - channel: '#devops'
    - from_name: saltbot
    - message: 'The scheduled backup for edX RP has failed.'
    - api_key: {{ slack_api_token }}
    - onfail:
        - salt: execute_enabled_backup_scripts

alert_devops_channel_on_success:
  slack.post_message:
    - channel: '#devops'
    - from_name: saltbot
    - message: 'The scheduled backup for edX RP has succeeded.'
    - api_key: {{ slack_api_token }}
    - require:
        - salt: execute_enabled_backup_scripts
        - salt: terminate_backup_instance_in_{{ ENVIRONMENT }}
