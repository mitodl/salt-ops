datadog:
  integrations:
    http_check:
      settings:
        instances:
          - name: mitx-production-lms-live
            url: 'https://lms.mitx.mit.edu'
            tls_verify: true
            content_match: 'Powered by Open edX'
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            tags:
              - mitx-production
          - name: mitx-production-cms-live
            url: 'https://studio.mitx.mit.edu'
            tls_verify: true
            content_match: 'Powered by Open edX'
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            tags:
              - mitx-production
          - name: gitreload-mitx-production-live
            url: 'https://prod-gr-rp.mitx.mit.edu/'
            tls_verify: true
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            http_response_status_code: 401
            tags:
              - mitx-production
          - name: mitx-production-lms-draft
            url: 'https://staging.mitx.mit.edu'
            tls_verify: true
            content_match: 'Powered by Open edX'
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            tags:
              - mitx-production
          - name: mitx-production-cms-draft
            url: 'https://studio-staging.mitx.mit.edu'
            tls_verify: true
            content_match: 'Powered by Open edX'
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            tags:
              - mitx-production
          - name: gitreload-mitx-production-draft
            url: 'https://gr-rp.mitx.mit.edu/'
            tls_verify: true
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            http_response_status_code: 401
            tags:
              - mitx-production
          - name: latex2edx
            url: 'https://studio-input-filter.mitx.mit.edu'
            tls_verify: true
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            tags:
              - mitx-production
          - name: mitxpro-production-lms
            url: 'https://courses.xpro.mit.edu/heartbeat'
            tls_verify: true
            content_match: "OK"
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            tags:
              - mitxpro-production
          - name: mitxpro-production-cms
            url: 'https://studio.xpro.mit.edu'
            tls_verify: true
            content_match: 'MIT xPRO'
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            tags:
              - mitxpro-production
          - name: odl-video-service-production
            url: 'https://video.odl.mit.edu/status?token=production-apps'
            tls_verify: true
            content_match: 'up'
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            tags:
              - odl-video-service-production-apps
          - name: discussions-reddit-production-apps
            url: 'https://discussions-reddit-production-apps.odl.mit.edu'
            tls_verify: true
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            http_response_status_code: 403
            tags:
              - mit-open-production
          - name: bootcamp-ecommerce-production
            url: 'https://bootcamp.odl.mit.edu'
            tls_verify: true
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            tags:
              - bootcamps
          - name: micromasters-production
            url: 'https://micromasters.mit.edu'
            tls_verify: true
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            tags:
              - micromasters
          - name: odl-open-discussions-production
            url: 'https://discussions.odl.mit.edu'
            tls_verify: true
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            tags:
              - mit-open
          - name: xpro-production
            url: 'https://xpro.mit.edu'
            tls_verify: true
            check_certificate_expiration: true
            days_warning: 30
            days_critical: 15
            tags:
              - mitxpro
