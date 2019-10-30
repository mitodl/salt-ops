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
    - Policy:
        Version: "2012-10-17"
        Statement:
          - Sid: "PublicRead"
            Effect: "Allow"
            Principal: "*"
            Action: "s3:GetObject"
            Resource:
              - "arn:aws:s3:::ol-eng-artifacts/*"
              - "arn:aws:s3:::ol-eng-artifacts"
