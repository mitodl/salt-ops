{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set PURPOSE = salt.environ.get('PURPOSE', 'current-residential-draft') %}
{% set env_dict = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set env_settings = env_dict.environments[ENVIRONMENT] %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', env_settings.vpc_name) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_settings.business_unit) %}

{% set subnet_ids = [] %}
{% for subnet in salt.boto_vpc.describe_subnets(subnet_names=[
    'public1-{}'.format(ENVIRONMENT),
    'public2-{}'.format(ENVIRONMENT),
    'public3-{}'.format(ENVIRONMENT)])['subnets'] %}
{% do subnet_ids.append('{0}'.format(subnet['id'])) %}
{% endfor %}

{% set slack_api_token = salt.vault.read('secret-operations/global/slack/slack_api_token').data.value %}
{% set purposes = env_settings.purposes %}
{% set app_image = salt.sdb.get('sdb://consul/xenial_ami_id') %}
{% set worker_image = salt.sdb.get('sdb://consul/xenial_ami_id') %}
{% set bucket_prefix = env_settings.secret_backends.aws.bucket_prefix %}
{% set edx_video_buckets = ['veda-upload', 'veda-delivery', 'veda-hotstore', 'edx-video', 'edx-video-delivery'] %}

{% for purpose in purposes %}
{% if purpose.app == 'video-pipeline' %}
create_sns_topics_for_veda_on_{{ purpose }}:
  boto_sns.present:
    - name: {{ purpose }}_video_upload_notification
    - subscriptions:
        - protocol: https
          endpoint: https://{{ purpose.domains[0] }}/api/ingest_from_s3/
    - region: us-east-1

{% for bucket in edx_video_buckets %}
create_{{ odl_video_bucket_prefix }}-{{ bucket_purpose }}-{{ bucket_suffix }}:
  boto_s3_bucket.present:
    - Bucket: {{ bucket_prefix }}-{{ bucket }}-{{ purpose }}-{{ environment }}
    - region: us-east-1
    - Versioning:
        Status: "Enabled"
    - Tagging:
        OU: {{ business_unit }}
        Department: {{ business_unit }}
        Environment: {{ environment }}
    {% if bucket.endswith('delivery') %}
    - CORSRules:
      - AllowedOrigin: ["*"]
        AllowedMethod: ["GET"]
        AllowedHeader: ["Authorization"]
        MaxAgeSconds: 3000
    - NotificationConfiguration:
        TopicConfigurations:
          - TopicArn: {% salt.boto_sns.get_arn(purpose ~ '_video_upload_notification') %}
            Events:
              - 's3:ObjectCreated:*'
    {% endif %}
{% endfor %}
{% for app_name, app_settings in purpose.instances.items() %}
{% do app_settings.security_groups.extend(['salt_master', 'consul-agent']) %}
load_{{ app_name }}_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/{{ app_name }}.conf
    - source: salt://orchestrate/aws/cloud_profiles/{{ app_name }}.conf
    - template: jinja

generate_{{ app_name }}_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_{{ app_name }}_map.yml
    - source: salt://orchestrate/aws/map_templates/instance_map.yml
    - template: jinja
    - makedirs: True
    - context:
        environment_name: {{ ENVIRONMENT }}
        num_instances: {{ app_settings.number }}
        service_name: {{ app_name }}
        roles:
          - {{ app_name }}
          - edx-video
        securitygroupid:
          {% for group_name app_settings.security_groups %}
          - {{ salt.boto_secgroup.get_group_id(
            '{}-{}'.format(group_name, ENVIRONMENT), vpc_name=VPC_NAME) }}
          {% endfor %}
        subnetids: {{ subnet_ids }}
        tags:
          app: {{ app_name }}
          business_unit: {{ BUSINESS_UNIT }}
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
          launch_date: {{ salt.status.time(format="%Y-%m-%d") }}
    - require:
        - file: load_{{ app_name }}_cloud_profile

deploy_{{ app_name }}_cloud_map:
  salt.runner:
    - name: cloud.map_run
    - path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_{{ app_name }}_map.yml
    - kwargs:
        parallel: True
    - require:
        - file: generate_{{ app_name }}_cloud_map_file

load_pillar_data_on_{{ app_name }}_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'P@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: deploy_{{ app_name }}_cloud_map

populate_mine_with_{{ app_name }}_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_{{ app_name }}_nodes

deploy_consul_agent_to_{{ app_name }}_nodes:
  salt.state:
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - sls:
        - consul
        - consul.dns_proxy

build_{{ app_name }}_nodes:
  salt.state:
    - tgt: 'G@roles:{{ app_name }} and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: deploy_consul_agent_to_{{ app_name }}_nodes
{% endif %}
{% endfor %}
