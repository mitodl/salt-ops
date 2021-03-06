{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set PURPOSE = salt.environ.get('PURPOSE', 'current-residential-draft') %}
{% set env_dict = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set env_settings = env_dict.environments[ENVIRONMENT] %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', env_settings.vpc_name) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_settings.business_unit) %}
{% set RUN_MIGRATIONS = salt.environ.get('RUN_MIGRATIONS', False) %}

{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    '{}-subnet-1'.format(ENVIRONMENT),
    '{}-subnet-2'.format(ENVIRONMENT),
    '{}-subnet-3'.format(ENVIRONMENT),
    '{}-subnet-4'.format(ENVIRONMENT)])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

{% set slack_api_token = salt.vault.read('secret-operations/global/slack/slack_api_token').data.value %}
{% set THEME_VERSION = salt.environ.get('THEME_VERSION', 'juniper') %}
{% set purposes = env_settings.purposes %}
{% set edx_codename = purposes[PURPOSE].versions.codename %}
{% set instance_name = 'edxapp-{}-{}-base'.format(ENVIRONMENT, edx_codename) %}
{% set worker_instance_name = 'edx-worker-{}-{}-base'.format(ENVIRONMENT, edx_codename) %}
{% if ENVIRONMENT == 'mitx-production' %}
{% set app_image = salt.sdb.get('sdb://consul/edx_mitx-qa_{}_ami_id'.format(edx_codename)) %}
{% set worker_image = salt.sdb.get('sdb://consul/edx_worker_mitx-qa_{}_ami_id'.format(edx_codename)) %}
{% else %}
{% set app_image = salt.sdb.get('sdb://consul/focal_ami_id') %}
{% set worker_image = salt.sdb.get('sdb://consul/focal_ami_id') %}
{% endif %}

update_edxapp_codename_value:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: sdb.set
    - arg:
        - 'sdb://consul/edx_codename'
        - '{{ edx_codename }}'

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
        purpose: {{ PURPOSE }}
        edx_codename: {{ edx_codename }}
    - vm_overrides:
        image: {{ app_image }}
        tag:
          OU: {{ BUSINESS_UNIT }}
          business_unit: {{ BUSINESS_UNIT }}
          environment: {{ ENVIRONMENT }}
          purpose: {{ PURPOSE }}
          edx_codename: {{ edx_codename }}
        network_interfaces:
          - DeviceIndex: 0
            AssociatePublicIpAddress: True
            SecurityGroupId:
              - {{ salt.boto_secgroup.get_group_id(
              'edx-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
              - {{ salt.boto_secgroup.get_group_id(
              'default', vpc_name=VPC_NAME) }}
              - {{ salt.boto_secgroup.get_group_id(
              'master-ssh-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
              - {{ salt.boto_secgroup.get_group_id(
              'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
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
        purpose: {{ PURPOSE }}
        edx_codename: {{ edx_codename }}
    - vm_overrides:
        image: {{ worker_image }}
        tag:
          OU: {{ BUSINESS_UNIT }}
          business_unit: {{ BUSINESS_UNIT }}
          environment: {{ ENVIRONMENT }}
          purpose: {{ PURPOSE }}
          edx_codename: {{ edx_codename }}
        network_interfaces:
          - DeviceIndex: 0
            AssociatePublicIpAddress: True
            SecurityGroupId:
              - {{ salt.boto_secgroup.get_group_id(
              'edx-worker-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
              - {{ salt.boto_secgroup.get_group_id(
              'default', vpc_name=VPC_NAME) }}
              - {{ salt.boto_secgroup.get_group_id(
              'master-ssh-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
              - {{ salt.boto_secgroup.get_group_id(
              'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
            SubnetId: {{ subnet_ids[0] }}
    - require:
        - file: load_edx_base_cloud_profile

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

saltutil_sync_all:
  salt.function:
    - name: saltutil.sync_all
    - tgt: 'P@roles:(edx-base|edx-base-worker) and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound

{# Deploy Consul agent first so that the edx deployment can use provided DNS endpoints #}
deploy_consul_agent_to_edx_nodes:
  salt.state:
    - tgt: 'P@roles:(edx-base|edx-base-worker) and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - sls:
        - consul
        - consul.dns_proxy

restart_consul_processes_to_pick_up_env_changes:
  salt.function:
    - tgt: 'P@roles:(edx-base|edx-base-worker) and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: service.restart
    - arg:
        - consul

build_edx_base_nodes:
  salt.state:
    - tgt: 'P@roles:(edx-base|edx-base-worker) and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: deploy_consul_agent_to_edx_nodes
    {% if RUN_MIGRATIONS %}
    - pillar:
        edx:
          ansible_flags: "-e migrate_db=yes"
    {% elif ENVIRONMENT == 'mitx-production' %}
    - pillar:
        edx:
          ansible_flags: "--tags install:configuration"
    {% endif %}

{% set previous_release = salt.sdb.get('sdb://consul/edxapp-{}-{}-release-version'.format(ENVIRONMENT, edx_codename))|int %}
{% set release_number = previous_release + 1 %}

{% if 'production' in ENVIRONMENT %}
compile_assets_for_edx_{{ PURPOSE }}:
  salt.function:
    - tgt: 'G@roles:edx-base and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: cmd.run
    - arg:
        - /edx/bin/edxapp-update-assets
    - kwarg:
        timeout: 900
    - require:
        - salt: build_edx_base_nodes
    - require_in:
        - salt: disable_minion_service_before_snapshot
        - salt: remove_master_key_from_minions
{% endif %}

remove_unattended_upgrades_service:
  salt.function:
    - tgt: 'P@roles:(edx-base|edx-base-worker) and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - name: pkg.remove
    - arg:
        - unattended-upgrades

{# Delete grains before snapshotting so they can be set when building from the image #}
{% for grain in ['business_unit', 'environment', 'purpose', 'roles'] %}
delete_{{ grain }}_from_grains:
  salt.function:
    - tgt: 'edx*{{ ENVIRONMENT}}*base'
    - tgt_type: compound
    - name: state.single
    - arg: 
      - grains.absent
    - kwarg:
        name: {{ grain }}
        force: True
        destructive: True
    - require_in:
        - boto_ec2: snapshot_edx_app_{{ ENVIRONMENT }}_node
        - boto_ec2: snapshot_edx_worker_{{ ENVIRONMENT }}_node
    - require:
        - salt: build_edx_base_nodes
{#        - salt: compile_assets_for_edx_{{ PURPOSE }} #}
{% endfor %}

disable_minion_service_before_snapshot:
  salt.function:
    - tgt: 'edx*{{ ENVIRONMENT}}*base'
    - tgt_type: glob
    - name: service.disable
    - arg:
        - salt-minion
    - require:
        - salt: build_edx_base_nodes

remove_master_key_from_minions:
  salt.function:
    - tgt: 'edx*{{ ENVIRONMENT}}*base'
    - tgt_type: glob
    - name: file.remove
    - arg:
        - /etc/salt/pki/minion/minion_master.pub
    - require:
        - salt: build_edx_base_nodes

snapshot_edx_app_{{ ENVIRONMENT }}_node:
  boto_ec2.snapshot_created:
    - name: edxapp_{{ ENVIRONMENT }}_{{ edx_codename }}_base_release_{{ release_number }}
    - ami_name: edxapp_{{ ENVIRONMENT }}_{{ edx_codename }}_base_release_{{ release_number }}
    - instance_name: {{ instance_name }}
    - wait_until_available: False

snapshot_edx_worker_{{ ENVIRONMENT }}_node:
  boto_ec2.snapshot_created:
    - name: edx_worker_{{ ENVIRONMENT }}_{{ edx_codename }}_base_release_{{ release_number }}
    - ami_name: edx_worker_{{ ENVIRONMENT }}_{{ edx_codename }}_base_release_{{ release_number }}
    - instance_name: {{ worker_instance_name }}
    - wait_until_available: False

update_release_version:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: sdb.set
    - arg:
        - 'sdb://consul/edxapp-{{ ENVIRONMENT }}-{{ edx_codename }}-release-version'
        - '{{ release_number }}'
    - require:
        - boto_ec2: snapshot_edx_app_{{ ENVIRONMENT }}_node
        - boto_ec2: snapshot_edx_worker_{{ ENVIRONMENT }}_node

alert_devops_channel_on_ami_build_failure:
  slack.post_message:
    - channel: '#general'
    - from_name: saltbot
    - message: 'The AMI build for edX {{ edx_codename }} {{ ENVIRONMENT }} release {{ release_number }} has failed.'
    - api_key: {{ slack_api_token }}
    - onfail:
        - boto_ec2: snapshot_edx_app_{{ ENVIRONMENT }}_node
        - boto_ec2: snapshot_edx_worker_{{ ENVIRONMENT }}_node
{#        - salt: compile_assets_for_edx_{{ PURPOSE }} #}

alert_devops_channel_on_ami_build_success:
  slack.post_message:
    - channel: '#general'
    - from_name: saltbot
    - message: 'The AMI build for edX {{ edx_codename }} {{ ENVIRONMENT }} release {{ release_number }} has succeeded.'
    - api_key: {{ slack_api_token }}
    - require:
        - boto_ec2: snapshot_edx_app_{{ ENVIRONMENT }}_node
        - boto_ec2: snapshot_edx_worker_{{ ENVIRONMENT }}_node
