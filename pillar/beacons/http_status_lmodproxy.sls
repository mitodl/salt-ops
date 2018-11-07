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
    - interval: 1800
