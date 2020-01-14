{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set minion_id = salt.grains.get('id', '') %}
{% set cert = salt.vault.cached_write('pki-intermediate-{}/issue/fluentd-client'.format(ENVIRONMENT), common_name='fluentd.{}.{}'.format(minion_id, ENVIRONMENT), cache_prefix=minion_id) %}
{% set fluentd_cert_path = salt.sdb.get('sdb://yaml/fluentd:cert_path') %}
{% set fluentd_cert_key_path = salt.sdb.get('sdb://yaml/fluentd:cert_key_path') %}
{% set ca_cert_path = salt.sdb.get('sdb://yaml/fluentd:ca_cert_path') %}

fluentd:
  overrides:
    version: "1.8.0"
    user: root
    group: root
  pki:
    ca_chain:
      content: __vault__::secret-operations/global/pki/ca_chain>data>value
      path: '/usr/local/share/ca-certificates/ca_chain.crt'
  cert:
    fluentd_cert:
      content: |
        {{ cert.data.certificate|indent(8)}}
      path: {{ fluentd_cert_path }}
    fluentd_key:
      content: |
        {{ cert.data.private_key|indent(8) }}
      path: {{ fluentd_cert_key_path }}
    ca_cert:
      content: |
        {{ cert.data.issuing_ca|indent(8) }}
      path: {{ ca_cert_path }}
  configs:
     fluentd_log:
       settings:
          - directive: label
            directive_arg: '@FLUENT_LOG'
            attrs:
              - nested_directives:
                - directive: filter
                  attrs:
                    - '@type': record_transformer
                    - nested_directives:
                      - directive: record
                        attrs:
                          - host: '"#{Socket.gethostname}"'
                - directive: match
                  directive_arg: 'fluent.*'
                  attrs:
                    - '@type': forward
                    - transport: tls
                    - tls_client_cert_path: {{ fluentd_cert_path }}
                    - tls_client_private_key_path: {{ fluentd_cert_key_path }}
                    - tls_ca_cert_path: {{ ca_cert_path }}
                    - tls_allow_self_signed_cert: 'true'
                    - tls_verify_hostname: 'false'
                    - nested_directives:
                      - directive: server
                        attrs:
                          - host: operations-fluentd.query.consul
                          - port: 5001

beacons:
  service:
    - services:
        fluentd:
          onchangeonly: True
          delay: 60
          disable_during_state_run: True
    - interval: 60
