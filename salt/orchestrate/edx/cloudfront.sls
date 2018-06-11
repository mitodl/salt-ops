{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT') %}
{% set env_dict = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set env_settings = env_dict.environments[ENVIRONMENT] %}
{% set VPC_NAME = salt.environ.get('VPC_NAME', env_settings.vpc_name) %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_settings.business_unit) %}

{% for purpose, settings in env_settings.purposes.items() %}
{% if '-live' in purpose %}
{% set purpose_prefix = purpose.rsplit('-', 1)[0] %}
{% set name = [purpose_prefix, ENVIRONMENT, 'cdn']|join('-') %}
provision_cloudfront_distribution_for_{{ purpose }}_in_{{ ENVIRONMENT }}:
  boto_cloudfront.present:
    - name: {{ name }}
    - tags:
        Environment: {{ ENVIRONMENT }}
        Name: {{ name }}
        business_unit: {{ BUSINESS_UNIT }}
        Department: {{ BUSINESS_UNIT }}
        OU: {{ BUSINESS_UNIT }}
        purpose: {{ purpose }}
    - config:
        Enabled: true
        Aliases:
          Quantity: 0
        CacheBehaviors:
          Quantity: 0
        CallerReference: {{ name }}
        Comment: ''
        CustomErrorResponses:
          Quantity: 0
        DefaultCacheBehavior:
          AllowedMethods:
            CachedMethods:
              Items:
              - HEAD
              - GET
              Quantity: 2
            Items:
            - HEAD
            - GET
            - OPTIONS
            Quantity: 3
          Compress: true
          DefaultTTL: 86400
          ForwardedValues:
            Cookies:
              Forward: none
            Headers:
              Items:
              - Host
              - Origin
              - Referer
              Quantity: 3
            QueryString: false
            QueryStringCacheKeys:
              Quantity: 0
          LambdaFunctionAssociations:
            Quantity: 0
          MaxTTL: 31536000
          MinTTL: 0
          SmoothStreaming: false
          TargetOriginId: Custom-{{ settings.domains.lms }}
          TrustedSigners:
            Enabled: false
            Quantity: 0
          ViewerProtocolPolicy: allow-all
        DefaultRootObject: ''
        HttpVersion: http2
        IsIPV6Enabled: true
        Logging:
          Bucket: ''
          Enabled: false
          IncludeCookies: false
          Prefix: ''
        Origins:
          Items:
          {% for suffix in ['live', 'draft'] %}
          {% for domain in ['lms', 'cms'] %}
          - CustomHeaders:
              Quantity: 0
            CustomOriginConfig:
              HTTPPort: 80
              HTTPSPort: 443
              OriginKeepaliveTimeout: 5
              OriginProtocolPolicy: match-viewer
              OriginReadTimeout: 30
              OriginSslProtocols:
                Items:
                - TLSv1.1
                - TLSv1.2
                Quantity: 2
            DomainName: {{ env_settings.purposes[purpose_prefix + '-' + suffix].domains[domain] }}
            Id: Custom-{{ env_settings.purposes[purpose_prefix + '-' + suffix].domains[domain] }}
            OriginPath: ''
          {% endfor %}
          {% endfor %}
          Quantity: 4
        PriceClass: PriceClass_100
        Restrictions:
          GeoRestriction:
            Quantity: 0
            RestrictionType: none
        ViewerCertificate:
          ACMCertificateArn: arn:aws:acm:us-east-1:610119931565:certificate/31cbdb62-7553-472b-979a-3063c3e1fddc
          Certificate: arn:aws:acm:us-east-1:610119931565:certificate/31cbdb62-7553-472b-979a-3063c3e1fddc
          CertificateSource: acm
          MinimumProtocolVersion: TLSv1.1_2016
          SSLSupportMethod: sni-only
        WebACLId: ''
{% endif %}
{% endfor %}
