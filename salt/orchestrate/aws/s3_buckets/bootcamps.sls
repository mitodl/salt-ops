{% for env in ['rc', 'ci', 'production'] %}
ol-bootcamps-app-{{ env }}:
  boto_s3_bucket.present:
    - Bucket: ol-bootcamps-app-{{ env }}
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - Tagging:
        OU: bootcamps
        business_unit: bootcamps
        Department: bootcamps
        Environment: {{ env }}
{% endfor %}
