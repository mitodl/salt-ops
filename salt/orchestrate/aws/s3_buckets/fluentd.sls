mitodl-data-lake:
  boto_s3_bucket.present:
    - Bucket: mitodl-data-lake
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - Tagging:
        OU: operations
        business_unit: operations
        Department: operations
        Environment: operations

odl-residential-tracking-data:
  boto_s3_bucket.present:
    - Bucket: odl-residential-tracking-data
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - Tagging:
        OU: residental
        business_unit: residential
        Department: residential
        Environment: mitx-production

odl-xpro-tracking-data:
  boto_s3_bucket.present:
    - Bucket: odl-xpro-edx-tracking-data
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - Tagging:
        OU: mitxpro
        business_unit: mitxpro
        Department: mitxpro
        Environment: mitxpro-production

odl-micromasters-ir-data:
  boto_s3_bucket.present:
    - Bucket: odl-residential-tracking-data
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - Tagging:
        OU: residental
        business_unit: residential
        Department: residential
        Environment: micromasters
