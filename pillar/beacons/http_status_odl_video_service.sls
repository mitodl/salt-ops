beacons:
  http_status:
    - sites:
        odl-video-rc-apps:
          url: "https://video-rc.odl.mit.edu/status?token=rc-apps"
          json_response:
            - path: 'certificate:status'
              value: up
            - path: 'status_all'
              value: up
