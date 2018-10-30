beacons:
  http_status:
    - sites:
        odl-video-rc-apps:
          url: "https://video-rc.odl.mit.edu/status?token=rc-apps"
          json_response:
            - path: 'certificate:status'
              value: up
              comp: '=='
            - path: 'status_all'
              value: up
              comp: '=='
        odl-video-production-apps:
          url: "https://video.odl.mit.edu/status?token=production-apps"
          json_response:
            - path: 'certificate:status'
              value: up
              comp: '=='
            - path: 'status_all'
              value: up
              comp: '=='
    - interval: 600
