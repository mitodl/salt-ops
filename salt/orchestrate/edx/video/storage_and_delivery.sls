{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set PURPOSE = salt.environ.get('PURPOSE', 'current-residential-draft') %}
{% set env_dict = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set env_settings = env_dict.environments[ENVIRONMENT] %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', env_settings.vpc_name) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_settings.business_unit) %}
{% set purposes = env_settings.purposes %}

{% set bucket_prefix = env_settings.secret_backends.aws.bucket_prefix %}

{% set edx_video_buckets = ['veda-upload', 'veda-delivery', 'veda-hotstore', 'video-upload', 'video-delivery'] %}

{% for purpose in purposes %}
{% if purpose.app == 'video-pipeline' %}
create_sns_topics_for_veda_on_{{ purpose }}:
  boto_sns.present:
    - name: {{ purpose }}_video_upload_notification
    - subscriptions:
        - protocol: https
          endpoint: https://{{ purpose.domains[0] }}
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
{% endif %}
{% endfor %}
