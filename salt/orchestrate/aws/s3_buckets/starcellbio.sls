{% for env in ['rc-apps', 'production-apps'] %}
scb-{{ env }}-microscopy-uploads:
  boto_s3_bucket.present:
    - Bucket: scb-{{ env }}-microscopy-uploads
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - Tagging:
        OU: starteam
        business_unit: starteam
        Department: starteam
        Environment: {{ env }}
{% endfor %}
