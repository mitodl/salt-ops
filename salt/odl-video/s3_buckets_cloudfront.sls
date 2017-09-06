{% set odl_video_bucket_prefix = 'odl-video-service' %}
{% set odl_video_bucket_suffix = ['ci', 'rc', 'prod'] %}
{% set odl_video_bucket_purposes = ['thumbnails', 'transcoded', 'uswitch', 'watch', 'dist'] %}

{% for bucket_sffix in odl_video_bucket_suffix %}
{% for bucket_purpose in odl_video_bucket_purposes %}
create_{{ bucket_prefix}}-{{ bucket_purpose }}-{{ bucket_suffix }}:
  boto_s3_bucket.present:
    - Bucket: {{ bucket_prefix}}-{{ bucket_purpose }}-{{ bucket_suffix }}
    - region: us-east-1
    - CORSRules:
      - AllowedOrigin: ["*"]
        AllowedMethod: ["GET"]
        AllowedHeader: ["Authorization"]
        MaxAgeSconds: 3000
    - Versioning:
        Status: "Enabled"
{% endfor %}
{% endfor %}

{% for odl_video_bucket_suffix in ['rc', 'prod'] %}
create_cloudfront_distribution_{{ odl_video_bucket_prefix }}-{{ odl_video_bucket_suffix }}:
  boto_cloudfront.present:
  - name: {{ odl_video_bucket_prefix }}-{{ odl_video_bucket_suffix }}
  - config:
      CacheBehaviors:
        Items:
        - AllowedMethods:
            CachedMethods:
              Items:
              - HEAD
              - GET
              - OPTIONS
            Items:
            - HEAD
            - GET
            - OPTIONS
          Compress: false
          DefaultTTL: 86400
          ForwardedValues:
            Cookies:
              Forward: none
            Headers:
              Items:
              - Access-Control-Request-Headers
              - Access-Control-Request-Method
              - Origin
            QueryString: false
          MaxTTL: 31536000
          MinTTL: 0
          PathPattern: /{{ odl_video_bucket_purposes }}-{{ odl_video_bucket_suffix }}*
          SmoothStreaming: false
          TargetOriginId: S3-{{ odl_video_bucket_prefix }}-{{ odl_video_bucket_purposes }}-{{ odl_video_bucket_suffix }}
          TrustedSigners:
            Enabled: false
          ViewerProtocolPolicy: redirect-to-https
      DefaultCacheBehavior:
        AllowedMethods:
          CachedMethods:
            Items:
            - HEAD
            - GET
            - OPTIONS
          Items:
          - HEAD
          - GET
          - OPTIONS
        Compress: false
        DefaultTTL: 86400
        ForwardedValues:
          Cookies:
            Forward: none
          Headers:
            Items:
            - Access-Control-Request-Headers
            - Access-Control-Request-Method
            - Origin
          QueryString: false
        MaxTTL: 31536000
        MinTTL: 0
        SmoothStreaming: false
        TargetOriginId: S3-{{ odl_video_bucket_prefix }}-{{ odl_video_bucket_suffix }}
        TrustedSigners:
          Enabled: true
          Items:
          - self
        ViewerProtocolPolicy: redirect-to-https
      DefaultRootObject: ''
      Enabled: true
      HttpVersion: http2
      IsIPV6Enabled: true
      Logging:
        Bucket: ''
        Enabled: false
        IncludeCookies: false
        Prefix: ''
      Origins:
        Items:
          DomainName: {{ odl_video_bucket_prefix }}-{{ odl_video_bucket_purposes }}-{{ odl_video_bucket_suffix }}.s3.amazonaws.com
          Id: S3-{{ odl_video_bucket_prefix }}-{{ odl_video_bucket_purposes }}-{{ odl_video_bucket_suffix }}
          OriginPath: ''
      PriceClass: PriceClass_All
      Restrictions:
        GeoRestriction:
          RestrictionType: none
      ViewerCertificate:
        CertificateSource: cloudfront
        CloudFrontDefaultCertificate: true
        MinimumProtocolVersion: SSLv3
      WebACLId: ''
  - tags: { 'Name': '{{ odl_video_bucket_prefix }}-{{ odl_video_bucket_purposes }}-{{ odl_video_bucket_suffix }}' }
{% endfor %}
