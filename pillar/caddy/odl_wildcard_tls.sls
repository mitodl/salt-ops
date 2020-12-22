caddy:
  config:
    apps:
      tls:
        certificates:
          load_pem:
            - certificate: __vault__::secret-operations/global/odl_wildcard_cert>data>value
              key: __vault__::secret-operations/global/odl_wildcard_cert>data>key
