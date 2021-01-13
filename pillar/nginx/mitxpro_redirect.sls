nginx:
  servers:
    managed:
      mitxpro-redirect:
        enabled: True
        config:
          - server:
              - server_name: mitxpro.mit.edu
              - listen: 80
              - listen: '443 ssl'
              - listen: '[::]:80'
              - listen: '[::]:443 ssl'
              # The certificate uses subject alternative names, including mitxpro.mit.edu.
              - ssl_certificate: /etc/letsencrypt/live/amps-web.amps.ms.mit.edu/cert.pem
              - ssl_certificate_key: /etc/letsencrypt/live/amps-web.amps.ms.mit.edu/privkey.pem
              - ssl_stapling: 'on'
              - ssl_stapling_verify: 'on'
              - ssl_session_timeout: 1d
              - ssl_session_tickets: 'off'
              - ssl_protocols: 'TLSv1.2 TLSv1.3'
              - ssl_ciphers: "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256\
                  :DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384\
                  :ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256\
                  :ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256"
              - ssl_prefer_server_ciphers: 'on'
              - resolver: 1.1.1.1
              - location /.well-known/:
                - alias: /usr/share/nginx/html/.well-known/
              - location ~*  ^/certificates/(.*)$:
                - return: 301 https://certificates.mitxpro.mit.edu/course/$1.pdf
              # The following redirect is for requests for /credentials/[id] that
              # are being proxied from the certificates.mitxpro.mit.edu
              # Cloudfront distribution.
              - location ~*  ^/credentials/(.*?)/.*$:
                - return: 301 https://certificates.mitxpro.mit.edu/program/$1.pdf
              - location /:
                - return: 301 https://xpro.mit.edu/
