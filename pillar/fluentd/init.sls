{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set minion_id = salt.grains.get('id', '') %}
{% set cert = salt.vault.cached_write('pki-intermediate-{}/issue/fluentd-client'.format(ENVIRONMENT), common_name='fluentd.{}.{}'.format(minion_id, ENVIRONMENT), cache_prefix=minion_id) %}
{% set fluentd_cert_path = sdb.get('sdb://yaml/fluentd:cert_path') %}
{% set fluentd_cert_key_path = sdb.get('sdb://yaml/fluentd:cert_key_path') %}
{% set ca_cert_path = sdb.get('sdb://yaml/fluentd:ca_cert_path') %}

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

beacons:
  service:
    - services:
        fluentd:
          onchangeonly: True
          delay: 60
          disable_during_state_run: True
    - interval: 60
