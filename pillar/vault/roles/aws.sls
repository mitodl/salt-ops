{% import_yaml salt.cp.cache_file("salt://environment_settings.yml") as env_settings %}
vault:
  roles:
    {% for bucket in salt.boto_s3_bucket.list()['Buckets'] %}
    read_write_delete_iam_bucket_access_for_{{ bucket.Name }}:
      backend: aws-mitx
      name: read-write-delete-{{ bucket.Name }}
      options:
        policy: "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"s3:GetObject\", \"s3:ListAllMyBuckets\", \"s3:ListBucket\", \"s3:ListObjects\", \"s3:PutObject\", \"s3:DeleteObject\", \"s3:*Acl\"], \"Resource\": [\"arn:aws:s3:::{{ bucket.Name }}\", \"arn:aws:s3:::{{ bucket.Name }}/*\"]}]}"
    read_and_write_iam_bucket_access_for_{{ bucket.Name }}:
      backend: aws-mitx
      name: read-write-{{ bucket.Name }}
      options:
        policy: "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"s3:GetObject\", \"s3:ListAllMyBuckets\", \"s3:ListBucket\", \"s3:ListObjects\", \"s3:PutObject\", \"s3:*Acl\"], \"Resource\": [\"arn:aws:s3:::{{ bucket.Name }}\", \"arn:aws:s3:::{{ bucket.Name }}/*\"]}]}"
    read_only_iam_bucket_access_for_{{ bucket.Name }}:
      backend: aws-mitx
      name: read-only-{{ bucket.Name }}
      options:
        policy: "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"s3:GetObject\", \"s3:ListAllMyBuckets\", \"s3:ListBucket\", \"s3:ListObjects\"], \"Resource\": [\"arn:aws:s3:::{{ bucket.Name }}\", \"arn:aws:s3:::{{ bucket.Name }}/*\"]}]}"
    {% endfor %}{# End of bucket loop #}
