{% from "orchestrate/aws_env_macro.jinja" import VPC_NAME, VPC_RESOURCE_SUFFIX,
 ENVIRONMENT, BUSINESS_UNIT, PURPOSE_PREFIX, subnet_ids with context %}

{% set slack_api_token = salt.vault.read('secret-operations/global/slack/slack_api_token').data.value %}
{% set EDX_VERSION = salt.environ.get('EDX_VERSION') %}
{% set THEME_VERSION = salt.environ.get('THEME_VERSION', 'ficus') %}
{% set env_settings = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}
{% set purposes = env_settings.purposes %}
{% set instance_name = 'edxapp-base-{}'.format(ENVIRONMENT) %}
{% set worker_instance_name = 'edx-worker-base-{}'.format(ENVIRONMENT) %}

load_edx_base_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/edx_base.conf
    - source: salt://orchestrate/aws/cloud_profiles/edx_base.conf
    - template: jinja

create_edx_baseline_instance_in_{{ ENVIRONMENT }}:
  salt.runner:
    - name: cloud.profile
    - prof: edx_base
    - instances:
        - {{ instance_name }}
    - grains:
        business_unit: {{ BUSINESS_UNIT }}
        environment: {{ ENVIRONMENT }}
        purpose: {{ PURPOSE_PREFIX }}-draft
    - vm_overrides:
        tag:
          business_unit: {{ BUSINESS_UNIT }}
          environment: {{ ENVIRONMENT }}
          purpose_prefix: {{ PURPOSE_PREFIX }}
        network_interfaces:
          - DeviceIndex: 0
            AssociatePublicIpAddress: True
            SecurityGroupId:
              - {{ salt.boto_secgroup.get_group_id(
              'edx-{}'.format(VPC_RESOURCE_SUFFIX), vpc_name=VPC_NAME) }}
              - {{ salt.boto_secgroup.get_group_id(
              'default', vpc_name=VPC_NAME) }}
              - {{ salt.boto_secgroup.get_group_id(
              'salt_master-{}'.format(VPC_RESOURCE_SUFFIX), vpc_name=VPC_NAME) }}
              - {{ salt.boto_secgroup.get_group_id(
              'consul-agent-{}'.format(VPC_RESOURCE_SUFFIX), vpc_name=VPC_NAME) }}
            SubnetId: {{ subnet_ids[0] }}
    - require:
        - file: load_edx_base_cloud_profile

create_edx_worker_baseline_instance_in_{{ ENVIRONMENT }}:
  salt.runner:
    - name: cloud.profile
    - prof: edx_worker_base
    - instances:
        - {{ worker_instance_name }}
    - grains:
        business_unit: {{ BUSINESS_UNIT }}
        environment: {{ ENVIRONMENT }}
        purpose: {{ PURPOSE_PREFIX }}-draft
    - vm_overrides:
        tag:
          business_unit: {{ BUSINESS_UNIT }}
          environment: {{ ENVIRONMENT }}
          purpose_prefix: {{ PURPOSE_PREFIX }}
        network_interfaces:
          - DeviceIndex: 0
            AssociatePublicIpAddress: True
            SecurityGroupId:
              - {{ salt.boto_secgroup.get_group_id(
              'edx-worker-{}'.format(VPC_RESOURCE_SUFFIX), vpc_name=VPC_NAME) }}
              - {{ salt.boto_secgroup.get_group_id(
              'default', vpc_name=VPC_NAME) }}
              - {{ salt.boto_secgroup.get_group_id(
              'salt_master-{}'.format(VPC_RESOURCE_SUFFIX), vpc_name=VPC_NAME) }}
              - {{ salt.boto_secgroup.get_group_id(
              'consul-agent-{}'.format(VPC_RESOURCE_SUFFIX), vpc_name=VPC_NAME) }}
            SubnetId: {{ subnet_ids[0] }}
    - require:
        - file: load_edx_base_cloud_profile

ensure_instance_profile_exists_for_edx:
  boto_iam_role.present:
    - name: edx-instance-role

load_pillar_data_on_edx_base_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'P@roles:(edx-base|edx-base-worker) and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: create_edx_worker_baseline_instance_in_{{ ENVIRONMENT }}
        - salt: create_edx_baseline_instance_in_{{ ENVIRONMENT }}

populate_mine_with_edx_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'P@roles:(edx-base|edx-base-worker) and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_edx_base_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_edx_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'P@roles:(edx-base|edx-base-worker) and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_edx_node_data

{# Deploy Consul agent first so that the edx deployment can use provided DNS endpoints #}
deploy_consul_agent_to_edx_nodes:
  salt.state:
    - tgt: 'P@roles:(edx-base|edx-base-worker) and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - sls:
        - consul
        - consul.dns_proxy

build_edx_base_nodes:
  salt.state:
    - tgt: 'P@roles:(edx-base|edx-base-worker) and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: deploy_consul_agent_to_edx_nodes
    {% if EDX_VERSION %}
    - pillar:
        edx:
          ansible_vars:
            edx_platform_version: {{ EDX_VERSION }}
          edxapp:
            custom_theme:
              branch: {{ THEME_VERSION }}
    {% endif %}

{% set previous_release = salt.sdb.get('sdb://consul/edxapp-release-version')|int %}
{% set release_number = previous_release + 1 %}

{# Delete grains before snapshotting so they can be set when building from the image #}
{% for grain in ['business_unit', 'environment', 'purpose', 'roles'] %}
delete_{{ grain }}_from_grains:
  salt.function:
    - tgt: 'edx*base-{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: grains.delkey
    - arg:
        - {{ grain }}
    - require_in:
        - boto_ec2: snapshot_edx_app_node
        - boto_ec2: snapshot_edx_worker_node
{% endfor %}

disable_minion_service_before_snapshot:
  salt.function:
    - tgt: 'edx*base-{{ ENVIRONMENT }}'
    - tgt_type: glob
    - name: service.disable
    - arg:
        - salt-minion

snapshot_edx_app_node:
  boto_ec2.snapshot_created:
    - name: edxapp_base_release_{{ release_number }}
    - ami_name: edxapp_base_release_{{ release_number }}
    - instance_name: {{ instance_name }}
    - wait_until_available: False

snapshot_edx_worker_node:
  boto_ec2.snapshot_created:
    - name: edx_worker_base_release_{{ release_number }}
    - ami_name: edx_worker_base_release_{{ release_number }}
    - instance_name: {{ worker_instance_name }}
    - wait_until_available: False

update_release_version:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: sdb.set
    - arg:
        - '{{ release_number }}'
    - require:
        - boto_ec2: snapshot_edx_app_node
        - boto_ec2: snapshot_edx_worker_node

alert_devops_channel_on_ami_build_failure:
  slack.post_message:
    - channel: '#general'
    - from_name: saltbot
    - message: 'The AMI build for edX release {{ release_number }} has failed.'
    - api_key: {{ slack_api_token }}
    - onfail:
        - boto_ec2: snapshot_edx_worker_node
        - boto_ec2: snapshot_edx_app_node

alert_devops_channel_on_ami_build_success:
  slack.post_message:
    - channel: '#general'
    - from_name: saltbot
    - message: 'The AMI build for edX release {{ release_number }} has succeeded.'
    - api_key: {{ slack_api_token }}
    - require:
        - boto_ec2: snapshot_edx_worker_node
        - boto_ec2: snapshot_edx_app_node
