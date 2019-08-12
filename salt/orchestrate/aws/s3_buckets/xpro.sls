{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% for env in ['mitxpro-qa', 'mitxpro-production'] %}
{% set env_data = env_settings.environments[env] %}
{% for purpose in env_data.purposes %}
{% set bucket_prefix = env_data.secret_backends.aws.bucket_prefix %}
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
        - GrantRead: "uri=http://acs.amazonaws.com/groups/global/AllUsers"
{% endfor %}
{% endfor %}

{% for env in ['rc', 'ci', 'production'] %}
xpro-app-{{ env }}:
  boto_s3_bucket.present:
    - Bucket: xpro-app-{{ env }}
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - Tagging:
        OU: mitxpro
        business_unit: mitxpro
        Department: mitxpro
        Environment: {{ env }}
{% endfor %}
