{% set app_name = 'amps-redirect' %}

nginx:
  install_from_source: False
  source_version: 1.15.1
  source_hash: c7206858d7f832b8ef73a45c9b8f8e436bcb1ee88db2bc85b8e438ecec9d5460
  certificates:
    odl_wildcard:
      public_cert: __vault__::secret-operations/global/odl_wildcard_cert>data>value
      private_key: __vault__::secret-operations/global/odl_wildcard_cert>data>key
  servers:
    managed:
      {{ app_name }}:
        enabled: True
        config:
          - server:
              - server_name: 'amps-web.amps.ms.mit.edu amps.odl.mit.edu'
              - listen: '80 default'
              - listen: '443 ssl'
              - listen: '[::]:80'
              - listen: '[::]:443 ssl'
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
              - location /courses/6/6.045/2015spring/L01/MIT-6.045-lec-mit-0000-2015may14-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/ef3aa2b5dbb14adc9c15452b0d27c436/?start=398
              - location /courses/6/6.045/2015spring/L01/MIT-6.045-lec-mit-0000-2015may07-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/c5691b38739d4a43a232bf3ef07f1646/?start=504
              - location /courses/6/6.045/2015spring/L01/MIT-6.045-lec-mit-0000-2015may05-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/b5cc48724aa5405c9fd7b1211a2b0b3c/
              - location /courses/6/6.045/2015spring/L01/MIT-6.045-lec-mit-0000-2015apr30-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/4656112ede89496fb100fe10b02fa304/?start=396
              - location /courses/6/6.045/2015spring/L01/MIT-6.045-lec-mit-0000-2015apr28-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/59219f99dd30490e9586ad960ad2691f/?start=463
              - location /courses/6/6.045/2015spring/L01/MIT-6.045-lec-mit-0000-2015apr23-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/9ea370cd18b14656a712e7cc723cf7a9/?start=393
              - location /courses/6/6.045/2015spring/L01/MIT-6.045-lec-mit-0000-2015apr16-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/201c33a2dab349359f5af23a293d9c5a/?start=333
              - location /courses/6/6.045/2015spring/L01/MIT-6.045-lec-mit-0000-2015apr14-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/b5cc48724aa5405c9fd7b1211a2b0b3c/
              - location /courses/6/6.045/2015spring/L01/MIT-6.045-lec-mit-0000-2015apr09-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/33abf21f4e174e6e8f21a5071c30a66f/?start=250
              - location /courses/6/6.045/2015spring/L01/MIT-6.045-lec-mit-0000-2015apr07-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/65da1d1388ce400983c9447f75883760/?start=278
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015mar31-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/5605b2609dcc4661b7aeb0c18645d5c9/?start=301
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015mar19-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/4c89dc64071f4c5ea5f948b80a2201bc/?start=128
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015mar17-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/3d86fd1c074840988b4480356e2d4746/?start=290
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015mar12-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/08eaaeb932d54d119e529deac416e804/?start=331
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015mar10-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/d7248606616240dca81337d163a28055/?start=172
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015mar05-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/bc78f4af98e9492cbef7278d92156b92/?start=170
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015mar03-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/bc78f4af98e9492cbef7278d92156b92/?start=170
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015feb26-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/7dcf75a64fa54356bc2e6f0a8e38fc79/?start=272
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015feb24-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/c973ebdcbca34ecf868cc12a0344d8f5/?start=268
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015feb19-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/9178561d53b5460db360c72bd9dec2b5/?start=430
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015feb12-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/5d64d5e504c140a19efb1b69b5385482/
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015feb05-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/2f043945501941e9a0fe35e5a4bbf782/
              - location /courses/6/6.045/2015spring/MIT-6.045-lec-mit-0000-2015feb03-0929-L01/:
                  - return: 301 https://video.odl.mit.edu/videos/7a11f55dd99d49349f377d2d87f0aef2/?start=341
              - location /:
                  - return: 301 https://docs.google.com/forms/d/e/1FAIpQLSdvkI2cPG1iMM4gN_KyKem4fNLh4irWzrmjX-JhcFXa51su5g/viewform?fbzx=2658557852628862500
