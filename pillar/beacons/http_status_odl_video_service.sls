beacons:
  http_status:
    - sites:
        odl-video-rc-apps:
          url: "https://video-rc.odl.mit.edu/status?token=rc-apps"
          status:
            - value: 400
              comp: '<'
            - value: 300
              comp: '>='
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
            - value: 300
              comp: '>='
          content:
            - path: 'certificate:status'
              value: up
              comp: '=='
            - path: 'status_all'
              value: up
              comp: '=='
    - interval: 10
