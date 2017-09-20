{% set odl_video_bucket_prefix = 'odl-video-service' %}
{% set odl_video_bucket_suffix = ['rc', 'prod'] %}
{% set odl_video_bucket_purposes = ['dist', 'thumbnails', 'transcoded', 'subtitles'] %}
{% set cloudfront_OriginAccessIdentity = (salt.boto_cloudfront.get_distribution()['local']['result']['distribution']['DistributionConfig']['Origins']['Items'][0]['S3OriginConfig']['OriginAccessIdentity']).split('/')[-1] %}

{% for bucket_suffix in odl_video_bucket_suffix %}
{% for bucket_purpose in odl_video_bucket_purposes %}
put_{{ bucket_prefix}}-{{ bucket_purpose }}-{{ bucket_suffix }}_policy:
  module.run:
    boto_s3_bucket.put_policy:
      - Bucket: {{ bucket_prefix }}-{{ bucket_purpose }}-{{ bucket_suffix }}
      - Policy:
          Version: "2008-10-17"
          Statement:
            - Sid: 1
              Effect: "Allow"
              Principal:
                AWS: "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity {{ cloudfront_OriginAccessIdentity }}"
              Action: "s3:GetObject"
              Resource: "arn:aws:s3:::{{ bucket_prefix}}-{{ bucket_purpose }}-{{ bucket_suffix }}/*"
{% endfor %}
{% endfor %}
