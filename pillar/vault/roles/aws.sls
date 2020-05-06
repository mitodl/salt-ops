{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}

vault:
  roles:
    {% for bucket in salt.boto_s3_bucket.list()['Buckets'] %}
    read_write_delete_iam_bucket_access_for_{{ bucket.Name }}:
      backend: aws-mitx
      name: read-write-delete-{{ bucket.Name }}
      options:
        policy_document: "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"s3:GetObject\", \"s3:ListAllMyBuckets\", \"s3:ListBucket\", \"s3:ListObjects\", \"s3:PutObject\", \"s3:DeleteObject\", \"s3:*Acl\"], \"Resource\": [\"arn:aws:s3:::{{ bucket.Name }}\", \"arn:aws:s3:::{{ bucket.Name }}/*\"]}]}"
    read_and_write_iam_bucket_access_for_{{ bucket.Name }}:
      backend: aws-mitx
      name: read-write-{{ bucket.Name }}
      options:
        policy_document: "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"s3:GetObject\", \"s3:ListAllMyBuckets\", \"s3:ListBucket\", \"s3:ListObjects\", \"s3:PutObject\", \"s3:*Acl\"], \"Resource\": [\"arn:aws:s3:::{{ bucket.Name }}\", \"arn:aws:s3:::{{ bucket.Name }}/*\"]}]}"
    read_only_iam_bucket_access_for_{{ bucket.Name }}:
      backend: aws-mitx
      name: read-only-{{ bucket.Name }}
      options:
        policy_document: "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"s3:GetObject\", \"s3:ListAllMyBuckets\", \"s3:ListBucket\", \"s3:ListObjects\"], \"Resource\": [\"arn:aws:s3:::{{ bucket.Name }}\", \"arn:aws:s3:::{{ bucket.Name }}/*\"]}]}"
    {% endfor %}{# End of bucket loop #}
    {% for env in ['ci', 'rc', 'production'] %}
    {% load_json as ovs_policy %}
    {
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:ListBucket",
            "s3:HeadObject",
            "s3:GetObject"
          ],
          "Resource": [
            "arn:aws:s3:::ttv_videos",
            "arn:aws:s3:::ttv_videos/*",
            "arn:aws:s3:::ttv_static",
            "arn:aws:s3:::ttv_static/*"
          ]
        },
        {
          "Resource": "*",
          "Action": [
            "elastictranscoder:Read*",
            "elastictranscoder:List*",
            "elastictranscoder:*Job",
            "elastictranscoder:*Preset",
            "iam:List*",
            "sns:List*",
            "sns:Publish"
          ],
          "Effect": "Allow"
        },
        {
          "Resource": [
            "arn:aws:s3:::odl-video-service*",
            "arn:aws:s3:::odl-video-service*/*"
          ],
          "Action": [
            "s3:HeadObject",
            "s3:GetObject",
            "s3:ListAllMyBuckets",
            "s3:ListBucket",
            "s3:ListObjects",
            "s3:PutObject",
            "s3:DeleteObject"
          ],
          "Effect": "Allow"
        },
        {
          "Resource": [
            "arn:aws:s3:::odl-video-service-{{ env }}/",
            "arn:aws:s3:::odl-video-service-{{ env }}-transcoded/",
            "arn:aws:s3:::odl-video-service-{{ env }}-thumbnails/",
            "arn:aws:s3:::odl-video-service-{{ env }}-subtitles/",
            "arn:aws:s3:::odl-video-service-{{ env }}/*",
            "arn:aws:s3:::odl-video-service-{{ env }}-transcoded/*",
            "arn:aws:s3:::odl-video-service-{{ env }}-thumbnails/*",
            "arn:aws:s3:::odl-video-service-{{ env }}-subtitles/*"
          ],
          "Action": [
            "s3:DeleteObject",
            "s3:DeleteObjectVersion",
            "s3:HeadObject",
            "s3:GetAccelerateConfiguration",
            "s3:GetBucketAcl",
            "s3:GetBucketCORS",
            "s3:GetBucketLocation",
            "s3:GetBucketLogging",
            "s3:GetBucketNotification",
            "s3:GetBucketPolicy",
            "s3:GetBucketTagging",
            "s3:GetBucketVersioning",
            "s3:GetBucketWebsite",
            "s3:GetLifecycleConfiguration",
            "s3:GetObject",
            "s3:GetObjectAcl",
            "s3:GetObjectTagging",
            "s3:GetObjectTorrent",
            "s3:GetObjectVersion",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging",
            "s3:GetObjectVersionTorrent",
            "s3:GetReplicationConfiguration",
            "s3:ListAllMyBuckets",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:ListBucketVersions",
            "s3:ListMultipartUploadParts",
            "s3:PutBucketWebsite",
            "s3:PutObject",
            "s3:PutObjectTagging",
            "s3:ReplicateDelete",
            "s3:ReplicateObject",
            "s3:RestoreObject"
          ],
          "Effect": "Allow",
          "Sid": "Stmt1496679856000"
        }
      ],
      "Version": "2012-10-17"
    }
    {% endload %}
    odl_video_iam_role_for_{{ env }}:
      backend: aws-mitx
      name: odl-video-service-{{ env }}
      options:
        policy_document: '{{ ovs_policy|json }}'
    {% load_json as mit_open_policy %}
    {
      "Statement": [
        {
          "Resource": [
            "arn:aws:s3:::odl-discussions-{{ env }}",
            "arn:aws:s3:::odl-discussions-{{ env }}/*",
            "arn:aws:s3:::open-learning-course-data-{{ env }}",
            "arn:aws:s3:::open-learning-course-data-{{ env }}/*"
          ],
          "Action": [
            "s3:HeadObject",
            "s3:Get*",
            "s3:List*",
            "s3:Put*",
            "S3:DeleteObject"
          ],
          "Effect": "Allow"
        },
        {
          "Resource": [
            "arn:aws:s3:::mitx-etl-xpro-production-mitxpro-production",
            "arn:aws:s3:::mitx-etl-xpro-production-mitxpro-production/*",
            "arn:aws:s3:::ol-olx-course-exports",
            "arn:aws:s3:::ol-olx-course-exports/*",
            "arn:aws:s3:::ocw-content-storage",
            "arn:aws:s3:::ocw-content-storage/*"
          ],
          "Action": [
            "s3:HeadObject",
            "s3:Get*",
            "s3:List*"
          ],
          "Effect": "Allow"
        }
      ],
      "Version": "2012-10-17"
    }
    {% endload %}
    mit_open_iam_role_for_{{ env }}:
      backend: aws-mitx
      name: mit-open-{{ env }}
      options:
        policy_document: '{{ mit_open_policy|json }}'
    {% endfor %}
