open_learning_software_artifacts:
  boto_s3_bucket.present:
    - Bucket: ol-eng-artifacts
    - Versioning:
        Status: Enabled
    - region: us-east-1
    - Tagging:
        OU: operations
        business_unit: operations
        Department: operations
        Environment: operations
    - ACL:
        - GrantRead: "uri=http://acs.amazonaws.com/groups/global/AllUsers"
