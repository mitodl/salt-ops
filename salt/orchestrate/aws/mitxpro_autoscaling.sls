{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'mitxpro-production') %}
{% set purpose = salt.grains.get('purpose', 'xpro-production') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}
{% set purpose_data = env_data.purposes[purpose] %}
{% set sqs_queue = env_data.provider_services.sqs.queue ~ '-' ~ ENVIRONMENT ~ '-autoscaling' %}
{% set sns_topic = env_data.provider_services.sns.topic ~ '-' ~ ENVIRONMENT ~ '-autoscaling' %}
{% set edx_codename = purpose_data.versions.codename %}

{% set region = 'us-east-1' %}
{% set AWS_ACCOUNT_ID = salt.vault.read('secret-operations/global/aws-account-id') %}
{% set release_number = salt.sdb.get('sdb://consul/edxapp-{}-{}-release-version'.format(ENVIRONMENT, edx_codename))|int %}
{% set ami_name = edxapp_ ~ ENVIRONMENT  ~ '_' ~ edx_codename ~ _base_release_ ~ release_number %}

create_{{ sqs_queue }}-sqs-queue:
  boto_sqs.present:
    - name: {{ sqs_queue }}
    - region: {{ region }}
    - attributes:
        Policy:
          Version: "2012-10-17"
          Id: "arn:aws:sqs:{{ region }}:{{ AWS_ACCOUNT_ID }}:{{ sqs_queue }}/SQSDefaultPolicy"
          Statement:
            - Effect: "Allow"
              Principal:
                AWS: ["arn:aws:iam::{{ AWS_ACCOUNT_ID }}:role/mitx-salt-master-role"]
              Action: "SQS:*"
              Resource: "arn:aws:sqs:{{ region }}:{{ AWS_ACCOUNT_ID }}:{{ sqs_queue }}"

create_{{ sns_topic }}-sns-topic:
  boto_sns.present:
    - name: {{ sns_topic }}
    - region: {{ region }}
    - subscriptions:
        - protocol: sqs
        - endpoint: 'arn:aws:sqs:{{ region }}:{{ AWS_ACCOUNT_ID }}:{{ sqs_queue }}'

create_autoscaling_group:
  boto_asg.present:
    - name: edx-{{ purpose }}-{{ ENVIRONMENT }}-autoscaling-group
    - launch_config_name: edx-{{ purpose }}-{{ ENVIRONMENT }}-launch-config
    - launch_config:
      - instance_profile_name: edx-instance-role
      - image_name: {{ ami_name }}
      - key_name: salt-master-prod
      - instance_type: {{ purpose_data.instances.edx.type }}
      - security_groups:
        - salt_master-{{ ENVIRONMENT }}
        - consul-agent-{{ ENVIRONMENT }}
        - edx-{{ ENVIRONMENT }}
    - min_size: {{ purpose_data.instances.edx.min_number }}
    - max_size: {{ purpose_data.instances.edx.max_number }}
    - desired_capacity: {{ purpose_data.instances.edx.min_number }}
    - region: {{ region }}
    - availability_zones:
      - us-east-1b
      - us-east-1c
      - us-east-1d
    - load_balancers:
      - edx-{{ purpose }}-{{ ENVIRONMENT }}
    - suspended_processes:
        - AddToLoadBalancer
        - AlarmNotification
    - scaling_policies:
        - name: ScaleUp
          adjustment_type: ChangeInCapacity
          as_name: edx-{{ purpose }}-{{ ENVIRONMENT }}-autoscaling-group
          cooldown: 1800
          scaling_adjustment: 2
        - name: ScaleDown
          adjustment_type: ChangeInCapacity
          as_name: edx-{{ purpose }}-{{ ENVIRONMENT }}-autoscaling-group
          cooldown: 1800
          scaling_adjustment: -1
    - alarms:
        CPU:
          name: edx-{{ purpose }}-{{ ENVIRONMENT }}-autoscaling-group-alarm
          attributes:
            metric: CPUUtilization
            namespace: AWS/EC2
            statistic: Average
            comparison: '>='
            threshold: 70.0
            period: 60
            evaluation_periods: 3
            unit: null
            description: 'edx-{{ purpose }}-{{ ENVIRONMENT }}-autoscaling-groups-alarm'
            alarm_actions: [ 'arn:aws:sns:{{ region }}:{{ AWS_ACCOUNT_ID }}:launch' ]
            ok_actions: [ 'arn:aws:sns:{{ region }}:{{ AWS_ACCOUNT_ID }}:ok' ]
    - notification_arn: 'arn:aws:sns:{{ region }}:{{ AWS_ACCOUNT_ID }}:{{ sns_topic }}'
    - notification_types:
        - autoscaling:EC2_INSTANCE_LAUNCH
        - autoscaling:EC2_INSTANCE_TERMINATE
