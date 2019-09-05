{% for env in ['mitxpro-qa', 'mitxpro-production'] %}

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
