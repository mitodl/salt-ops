open-learning-course-data:
  boto_s3_bucket.present:
    - Bucket: open-learning-course-data
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - Tagging:
        OU: mit-open
        business_unit: mit-open
        Department: mit-open
        Environment: operations

{% for env in ['rc', 'ci'] %}
open-learning-course-data-{{ env }}:
  boto_s3_bucket.present:
    - Bucket: open-learning-course-data-{{ env }}
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - Tagging:
        OU: mit-open
        business_unit: mit-open
        Department: mit-open
        Environment: operations
{% endfor %}
