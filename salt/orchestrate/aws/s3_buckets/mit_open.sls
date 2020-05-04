{% for env in ['rc', 'ci', 'production'] %}
open-learning-course-data-{{ env }}:
  boto_s3_bucket.present:
    - Bucket: open-learning-course-data-{{ env }}
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - CORSRules:
        - AllowedHeaders:
            - '*'
          AllowedMethods:
            - GET
          AllowedOrigins:
            - '*'
          MaxAgeSeconds: 300
    - Tagging:
        OU: mit-open
        business_unit: mit-open
        Department: mit-open
        Environment: operations
{% endfor %}
