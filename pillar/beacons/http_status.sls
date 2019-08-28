beacons:
  http_status:
    - sites:
        lmodproxy-qa:
          url: "https://lmodproxyqa.odl.mit.edu/status"
          status:
            - value: 200
              comp: '=='
          content:
            - path: 'status'
              value: ok
              comp: '=='
        lmodproxy-prod:
          url: "https://lmodproxyprod.odl.mit.edu/status"
          status:
            - value: 200
              comp: '=='
          content:
            - path: 'status'
              value: ok
              comp: '=='
        odl-video-rc-apps:
          url: "https://video-rc.odl.mit.edu/status?token=rc-apps"
          status:
            - value: 400
              comp: '<'
          content:
            - path: 'certificate:status'
              value: up
              comp: '=='
            - path: 'status_all'
              value: up
              comp: '=='
        odl-video-production-apps:
          url: "https://video.odl.mit.edu/status?token=production-apps"
          status:
            - value: 400
              comp: '<'
          content:
            - path: 'certificate:status'
              value: up
              comp: '=='
            - path: 'status_all'
              value: up
              comp: '=='
    - interval: 1800
