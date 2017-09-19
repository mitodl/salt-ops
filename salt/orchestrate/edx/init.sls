{% from "orchestrate/aws_env_macro.jinja" import VPC_NAME, VPC_RESOURCE_SUFFIX,
 ENVIRONMENT, BUSINESS_UNIT, PURPOSE_PREFIX, subnet_ids with context %}

{% set ANSIBLE_FLAGS = salt.environ.get('ANSIBLE_FLAGS') %}
{% set env_settings = salt.pillar.get('environments:{}'.format(ENVIRONMENT)) %}
{% set purposes = env_settings.purposes %}
{% set bucket_prefixes = env_settings.secret_backends.aws.bucket_prefixes %}
{% set release_version = salt.sdb.get('sdb://consul/edxapp-release-version') %}
{% set launch_date = salt.status.time(format="%Y-%m-%d") %}

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
    - name: /etc/salt/cloud.maps.d/{{ VPC_RESOURCE_SUFFIX }}_edx_map.yml
    - source: salt://orchestrate/aws/map_templates/edx.yml
    - template: jinja
    - makedirs: True
    - context:
        business_unit: {{ BUSINESS_UNIT }}
        environment_name: {{ ENVIRONMENT }}
        purpose_prefix: {{ PURPOSE_PREFIX }}
        securitygroupids:
          edxapp: {{ salt.boto_secgroup.get_group_id(
              'edx-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          edx-worker: {{ salt.boto_secgroup.get_group_id(
              'edx-worker-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          default: {{ salt.boto_secgroup.get_group_id(
              'default', vpc_name=VPC_NAME) }}
          salt-master: {{ salt.boto_secgroup.get_group_id(
            'salt_master-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          consul-agent: {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids }}
        tags:
          release-version: '{{ release_version }}'
          launch-date: '{{ launch_date }}'
        profile_overrides:
          userdata_file: '/etc/salt/cloud.d/edx_userdata.yml'
        app_types:
          draft: {{ purposes['{}-draft'.format(PURPOSE_PREFIX)].num_instances }}
          live:  {{ purposes['{}-live'.format(PURPOSE_PREFIX)].num_instances }}
    - require:
        - file: load_edx_cloud_profile
        - file: load_edx_worker_cloud_profile

ensure_instance_profile_exists_for_edx:
  boto_iam_role.present:
    - name: edx-instance-role

{% for bucket in bucket_prefixes %}
{% for type in ['draft', 'live'] %}
create_edx_s3_bucket_{{ bucket }}_{{ PURPOSE_PREFIX }}-{{ type }}_{{ ENVIRONMENT }}:
  boto_s3_bucket.present:
    - Bucket: {{ bucket }}-{{ PURPOSE_PREFIX }}-{{ type }}-{{ ENVIRONMENT }}
    - region: us-east-1
    - Versioning:
       Status: "Enabled"
{% endfor %}
{% endfor %}

deploy_edx_cloud_map:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: saltutil.runner
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/{{ VPC_RESOURCE_SUFFIX }}_edx_map.yml
        parallel: True
        full_return: True
    - require:
        - file: generate_edx_cloud_map_file

sync_external_modules_for_edx_nodes:
  salt.function:
    - name: saltutil.sync_all
    - tgt: 'P@roles:(edx|edx-worker) and G@environment:{{ ENVIRONMENT }} and G@release-version:{{ release_version }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - require:
        - salt: deploy_edx_cloud_map

load_pillar_data_on_edx_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'P@roles:(edx|edx-worker) and G@environment:{{ ENVIRONMENT }} and G@release-version:{{ release_version }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - require:
        - salt: deploy_edx_cloud_map

populate_mine_with_edx_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'P@roles:(edx|edx-worker) and G@environment:{{ ENVIRONMENT }} and G@release-version:{{ release_version }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_edx_nodes

{# Deploy Consul agent first so that the edx deployment can use provided DNS endpoints #}
deploy_consul_agent_to_edx_nodes:
  salt.state:
    - tgt: 'P@roles:(edx|edx-worker) and G@environment:{{ ENVIRONMENT }} and G@release-version:{{ release_version }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - sls:
        - consul
        - consul.dns_proxy

restart_consul_service_to_load_updated_configs:
  salt.function:
    - tgt: 'P@roles:(edx|edx-worker) and G@environment:{{ ENVIRONMENT }} and G@release-version:{{ release_version }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - name: service.restart
    - arg:
        - consul
    - require:
        - salt: deploy_consul_agent_to_edx_nodes

build_edx_nodes:
  salt.state:
    - tgt: 'P@roles:(edx|edx-worker) and G@environment:{{ ENVIRONMENT }} and G@release-version:{{ release_version }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: deploy_consul_agent_to_edx_nodes
        - salt: restart_consul_service_to_load_updated_configs
    {% if ANSIBLE_FLAGS %}
    - pillar:
        edx:
          ansible_flags: "{{ ANSIBLE_FLAGS }}"
    {% endif %}

{# Restart all of the supervisor processes to ensure that the updated settings get picked up #}
restart_supervisor_processes_after_deploy:
  salt.function:
    - tgt: 'P@roles:(edx|edx-worker) and G@environment:{{ ENVIRONMENT }} and G@release-version:{{ release_version }} and G@launch-date:{{ launch_date }}'
    - tgt_type: compound
    - name: supervisord.restart
    - arg:
        - all
    - kwarg:
        bin_env: /edx/bin/supervisorctl
