{% for app_name in ['edxapp', 'edx-worker'] %}
{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'mitxpro-production') %}

# Using QA AMI build to deploy production instances 
{% set AMI_ENV = salt.environ.get('AMI_ENV', 'mitxpro-qa') %}

{% set purpose = salt.environ.get('PURPOSE', 'xpro-production') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set VPC_NAME = env_data.vpc_name %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}
{% set purpose_data = env_data.purposes[purpose] %}
{% set sqs_queue = env_data.provider_services[app_name].sqs.queue ~ '-' ~ ENVIRONMENT ~ '-autoscaling' %}
{% set sns_topic = env_data.provider_services[app_name].sns.topic ~ '-' ~ ENVIRONMENT ~ '-autoscaling' %}
{% set edx_codename = purpose_data.versions.codename %}
{% set env_suffix = ENVIRONMENT.split('-')[1] %}
{% set security_groups = ['{}-salt-minion'.format(ENVIRONMENT),
                          '{}-consul-agent'.format(purpose), 'default',
                          'mitxpro-edxapp-access-{}'.format(env_suffix)] %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(vpc_id=salt.boto_vpc.describe_vpcs(name=VPC_NAME).vpcs[0].id).subnets|map(attribute='id')|list %}

{% set region = 'us-east-1' %}
{% set AWS_ACCOUNT_ID = salt.vault.read('secret-operations/global/aws-account-id').data.value %}
{% set release_number = salt.sdb.get('sdb://consul/edxapp-{}-{}-release-version'.format(ENVIRONMENT, edx_codename))|int %}
{% set ami_name = app_name.replace('-', '_') ~ '_' ~ AMI_ENV  ~ '_' ~ edx_codename ~ '_base_release_' ~ release_number %}
{% set elb_name = 'edx-{purpose}-{env}'.format(purpose=purpose, env=ENVIRONMENT)[:32].strip('-') %}
{% set min_size = purpose_data.instances[app_name].min_number %}
{% set max_size = purpose_data.instances[app_name].max_number %}
{% set instance_type = purpose_data.instances[app_name].type %}

create_{{ sqs_queue }}-sqs-queue:
  boto_sqs.present:
    - name: {{ sqs_queue }}
    - region: {{ region }}
    - attributes:
        Policy:
          Id: arn:aws:sqs:{{ region }}:{{ AWS_ACCOUNT_ID }}:{{ sqs_queue }}/SQSDefaultPolicy
          Statement:
            - Action: SQS:*
              Effect: Allow
              Principal:
                AWS:
                - arn:aws:iam::{{ AWS_ACCOUNT_ID }}:role/mitx-salt-master-role
              Resource: arn:aws:sqs:{{ region }}:{{ AWS_ACCOUNT_ID }}:{{ sqs_queue }}
            - Action: SQS:SendMessage
              Condition:
                ArnEquals:
                  aws:SourceArn: arn:aws:sns:{{ region }}:{{ AWS_ACCOUNT_ID }}:{{ sqs_queue
                    }}
              Effect: Allow
              Principal: '*'
              Resource: arn:aws:sqs:{{ region }}:{{ AWS_ACCOUNT_ID }}:{{ sqs_queue }}
          Version: '2012-10-17'

create_{{ sns_topic }}-sns-topic:
  boto_sns.present:
    - name: {{ sns_topic }}
    - region: {{ region }}
    - subscriptions: [{'protocol': 'sqs', 'endpoint': 'arn:aws:sqs:{{ region }}:{{ AWS_ACCOUNT_ID }}:{{ sqs_queue }}'}]
    - require:
        - boto_sqs: create_{{ sqs_queue }}-sqs-queue

create_autoscaling_group_for_{{ app_name }}:
  boto_asg.present:
    - name: {{ app_name }}-{{ purpose }}-{{ ENVIRONMENT }}-autoscaling-group
    - launch_config_name: {{ app_name }}-{{ purpose }}-{{ ENVIRONMENT }}-launch-config
    - launch_config:
      - instance_profile_name: edx-instance-role
      - image_name: {{ ami_name }}
      - key_name: salt-production
      - instance_type: {{ instance_type }}
      - associate_public_ip_address: True
      - security_groups:
        {% for group_name in security_groups %}
          - {{ salt.boto_secgroup.get_group_id(group_name, vpc_name=VPC_NAME) }}
        {% endfor %}
      - block_device_mappings:
        - '/dev/sda1':
            size: 25
            volume_type: 'gp2'
            encrypted: true
    - min_size: {{ min_size }}
    - max_size: {{ max_size }}
    - desired_capacity: {{ min_size }}
    - health_check_type: EC2
    - region: {{ region }}
    # - tags:
    #     'Environment': {{ ENVIRONMENT }}
    #     'purpose': {{ purpose }}
    #     'OU': {{ BUSINESS_UNIT }}
    - availability_zones:
      - us-east-1b
      - us-east-1c
      - us-east-1d
    - vpc_zone_identifier: {{ subnet_ids|tojson }}
    {% if 'edxapp' in app_name %}
    - load_balancers:
      - {{ elb_name }}
    {% endif %}
    # - suspended_processes:
    #     - AlarmNotification
    # - scaling_policies:
    #     - name: ScaleUp
    #       adjustment_type: ChangeInCapacity
    #       as_name: {{ app_name }}-{{ ENVIRONMENT }}-autoscaling-group
    #       cooldown: 1800
    #       scaling_adjustment: 2
    #     - name: ScaleDown
    #       adjustment_type: ChangeInCapacity
    #       as_name: {{ app_name }}-{{ purpose }}-{{ ENVIRONMENT }}-autoscaling-group
    #       cooldown: 1800
    #       scaling_adjustment: -1
    # - alarms:
    #     CPU:
    #       name: {{ app_name }}-{{ purpose }}-{{ ENVIRONMENT }}-autoscaling-group-alarm
    #       attributes:
    #         metric: CPUUtilization
    #         namespace: AWS/EC2
    #         statistic: Average
    #         comparison: '>='
    #         threshold: 70.0
    #         period: 60
    #         evaluation_periods: 3
    #         unit: null
    #         description: '{{ app_name }}-{{ purpose }}-{{ ENVIRONMENT }} ASG alarm'
    #         alarm_actions: [ 'arn:aws:sns:{{ region }}:{{ AWS_ACCOUNT_ID }}:launch' ]
    #         ok_actions: [ 'arn:aws:sns:{{ region }}:{{ AWS_ACCOUNT_ID }}:ok' ]
    # - notification_arn: 'arn:aws:sns:{{ region }}:{{ AWS_ACCOUNT_ID }}:{{ sns_topic }}'
    # - notification_types:
    #     - "autoscaling:EC2_INSTANCE_LAUNCH"
    #     - "autoscaling:EC2_INSTANCE_TERMINATE"
    - require:
        - boto_sns: create_{{ sns_topic }}-sns-topic
{% endfor %}
