{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% for env in ['mitxpro-qa', 'mitxpro-production', 'mitx-qa', 'mitx-production'] %}
{% set env_data = env_settings.environments[env] %}
{% for purpose in env_data.purposes %}
{% set bucket_prefix = env_data.secret_backends.aws.bucket_prefix %}

{% for use in bucket_uses %}
create_edx_s3_bucket_{{ use }}_{{ purpose }}_{{ ENVIRONMENT }}:
  boto_s3_bucket.present:
    - Bucket: {{ bucket_prefix }}-{{ use }}-{{ purpose }}-{{ ENVIRONMENT }}
    - region: us-east-1
    - Versioning:
       Status: "Enabled"
    {% if use == 'storage' %}
    - CORSRules:
        - AllowedHeaders:
            - "*"
          AllowedMethods:
            - GET
            - POST
            - PUT
          AllowedOrigins:
            - "*"
          MaxAgeSeconds: 3000
    {% endif %}
{% endfor %}

video_uploads_bucket_{{ purpose }}_{{ env }}:
  boto_s3_bucket.present:
    - Bucket: {{ bucket_prefix }}-edx-video-upload-{{ purpose }}-{{ env }}
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - Tagging:
        OU: mitxpro
        business_unit: mitxpro
        Department: mitxpro
        Environment: {{ env }}
    - ACL:
        GrantRead: "uri=http://acs.amazonaws.com/groups/global/AllUsers"
    - Policy:
        Version: "2012-10-17"
        Statement:
          - Sid: "PublicRead"
            Effect: "Allow"
            Principal: "*"
            Action: "s3:GetObject"
            Resource: "arn:aws:s3:::{{ bucket_prefix }}-edx-video-upload-{{ purpose }}-{{ env }}/*"
{% endfor %}
{% endfor %}
