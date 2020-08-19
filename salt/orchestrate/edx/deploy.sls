{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'mitx-qa') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set PURPOSES = salt.environ.get('PURPOSES', 'current-residential-draft,current-residential-live').split(',') %}
{% set VPC_NAME = env_data.vpc_name %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}
{% set launch_date = salt.status.time(format="%Y-%m-%d") %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|map(attribute='id')|list|sort(reverse=True) %}
{% set ANSIBLE_FLAGS = salt.environ.get('ANSIBLE_FLAGS') %}
{% set defined_purposes = env_data.purposes %}
{% set edx_tracking_bucket = 'odl-{}-tracking-backup'.format(BUSINESS_UNIT) %}

load_edx_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/edx.conf
    - source: salt://orchestrate/aws/cloud_profiles/edx.conf
    - template: jinja

load_edx_worker_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/edx_worker.conf
    - source: salt://orchestrate/aws/cloud_profiles/edx-worker.conf
    - template: jinja

{# Because these are being launched from pre-built AMIs we need to #}
{# remove the existing minion keys and ensure that nothing is locking #}
{# the package manager during bootstrap #}
write_out_edx_userdata_file:
  file.managed:
    - name: /etc/salt/cloud.d/edx_userdata.yml
    - contents: |
        #cloud-config
        bootcmd:
          - [cloud-init-per, once, regenkey, rm, -r, /etc/salt/pki/minion]
          - [cloud-init-per, once, resetconsul, rm, -r, /var/lib/consul]
          - [apt-get, remove, -y, unattended-upgrades]
    - makedirs: True

generate_edx_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_edx_map.yml
    - source: salt://orchestrate/aws/map_templates/edx.yml
    - template: jinja
    - makedirs: True
    - context:
        business_unit: {{ BUSINESS_UNIT }}
        environment_name: {{ ENVIRONMENT }}
        securitygroupids:
          edxapp: {{ salt.boto_secgroup.get_group_id(
              'edx-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          edx-worker: {{ salt.boto_secgroup.get_group_id(
              'edx-worker-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          default: {{ salt.boto_secgroup.get_group_id(
              'default', vpc_name=VPC_NAME) }}
          salt-master: {{ salt.boto_secgroup.get_group_id(
            'master-ssh-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          consul-agent: {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids|tojson }}
        tags:
          launch-date: '{{ launch_date }}'
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
        profile_overrides:
          userdata_file: '/etc/salt/cloud.d/edx_userdata.yml'
        app_types:
          {% for purpose_name in PURPOSES %}
          {{ purpose_name }}:
            instances: {{ defined_purposes[purpose_name].instances | tojson }}
          {% endfor %}
    - require:
        - file: load_edx_cloud_profile
        - file: load_edx_worker_cloud_profile

ensure_tracking_bucket_exists:
  boto_s3_bucket.present:
    - Bucket: {{ edx_tracking_bucket }}
    - region: us-east-1

ensure_instance_profile_exists_for_tracking:
  boto_iam_role.present:
    - name: edx-{{ ENVIRONMENT }}-instance-role
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

deploy_edx_cloud_map:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: saltutil.runner
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_edx_map.yml
        parallel: True
        full_return: True
    - require:
        - file: generate_edx_cloud_map_file

{% for purpose in PURPOSES %}
{% set codename = defined_purposes[purpose].versions.codename %}
{% set release_version = salt.sdb.get('sdb://consul/edxapp-{}-{}-release-version'.format(ENVIRONMENT, codename)) %}
sync_external_modules_for_{{ purpose }}_{{ codename }}_edx_nodes:
  salt.function:
    - name: saltutil.sync_all
    - tgt: 'P@roles:(edx|edx-worker) and G@environment:{{ ENVIRONMENT }} and G@release-version:{{ release_version }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - require:
        - salt: deploy_edx_cloud_map

{# Deploy Consul agent first so that the edx deployment can use provided DNS endpoints #}
deploy_consul_agent_to_{{ purpose }}_{{ codename }}_edx_nodes:
  salt.state:
    - tgt: 'P@roles:(edx|edx-worker) and G@environment:{{ ENVIRONMENT }} and G@release-version:{{ release_version }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - sls:
        - consul
        - consul.dns_proxy

restart_consul_service_on_{{ purpose }}_{{ codename }}_edx_nodes_to_load_updated_configs:
  salt.function:
    - tgt: 'P@roles:(edx|edx-worker) and G@environment:{{ ENVIRONMENT }} and G@release-version:{{ release_version }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - name: service.restart
    - arg:
        - consul
    - require:
        - salt: deploy_consul_agent_to_{{ purpose }}_{{ codename }}_edx_nodes

run_ansible_configuration_on_{{ purpose }}_{{ codename }}_edx_nodes:
  salt.state:
    - tgt: 'P@roles:(edx|edx-worker) and G@environment:{{ ENVIRONMENT }} and G@release-version:{{ release_version }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - highstate: True
    - pillar:
        edx:
          ansible_flags: "--tags install:configuration"

{# Restart all of the supervisor processes to ensure that the updated settings get picked up #}
restart_supervisor_processes_on_{{ purpose }}_{{ codename }}_edx_nodes_after_deploy:
  salt.function:
    - tgt: 'P@roles:(edx|edx-worker) and G@environment:{{ ENVIRONMENT }} and G@release-version:{{ release_version }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - name: supervisord.restart
    - arg:
        - all
    - kwarg:
        bin_env: /edx/bin/supervisorctl
{% endfor %}
