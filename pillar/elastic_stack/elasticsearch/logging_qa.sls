{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set minion_id = salt.grains.get('id', '') %}
{% set cert = salt.vault.cached_write('pki-intermediate-{}/issue/es-xpack'.format(ENVIRONMENT), common_name='es-xpack.{}.{}'.format(minion_id, ENVIRONMENT), cache_prefix=minion_id) %}
{% set xpack_cert_path = salt.sdb.get('sdb://yaml/xpack:cert_path') %}
{% set xpack_cert_key_path = salt.sdb.get('sdb://yaml/xpack:cert_key_path') %}
{% set ca_cert_path = salt.sdb.get('sdb://yaml/xpack:ca_cert_path') %}

elastic_stack:
  elasticsearch:
    cert:
      xpack_cert:
        content: |
          {{ cert.data.certificate|indent(8)}}
        path: {{ xpack_cert_path }}
      xpack_key:
        content: |
          {{ cert.data.private_key|indent(8) }}
        path: {{ xpack_cert_key_path }}
      ca_cert:
        content: |
          {{ cert.data.issuing_ca|indent(8) }}
        path: {{ ca_cert_path }}
    configuration_settings:
      cluster.name: {{ ENVIRONMENT }}
      discovery.ec2.tag.escluster: {{ ENVIRONMENT }}
      gateway.recover_after_nodes: 2
      gateway.expected_nodes: 3
      gateway.recover_after_time: 5m
      cloud.node.auto_attributes: true
      network.host: [_eth0_, _lo_]
      path.data: /var/lib/elasticsearch/data
      discovery.seed_providers: ec2
      xpack.license.self_generated.type: basic
      xpack.security.enabled: true
      # SSL/TLS incoming to ES cluster
      xpack.security.http.ssl.enabled: true
      xpack.security.http.ssl.key:  /etc/elasticsearch/xpack.key 
      xpack.security.http.ssl.certificate: /etc/elasticsearch/xpack.crt
      xpack.security.http.ssl.certificate_authorities: [ "/etc/elasticsearch/ca.crt" ]
      # TLS between ES nodes in cluster
      xpack.security.transport.ssl.enabled: true
      xpack.security.transport.ssl.verification_mode: certificate 
      xpack.security.transport.ssl.key: /etc/elasticsearch/xpack.key 
      xpack.security.transport.ssl.certificate: /etc/elasticsearch/xpack.crt 
      xpack.security.transport.ssl.certificate_authorities: [ "/etc/elasticsearch/ca.crt" ]
    plugins:
      - name: discovery-ec2
      - name: repository-s3

    # There seems to be a bug in
    # salt.states.elasticsearch.index_template_present, which causes it to fail
    # without a message, so we're going to update index templates manually until
    # it's sorted out. This is where you would specify the template:
    #
    # index_templates:
    #   - name: logstash
    #     definition:
    #       template: logstash-*
    #       settings:
    #         index:
    #           refresh_interval: 5s
    #           number_of_shards: 5
    #           number_of_replicas: 1
    #       mappings:
    #         fluentd:
    #           dynamic_templates:
    #             - strings:
    #                 match_mapping_type: string
    #                 mapping:
    #                   type: text
    #                   fields:
    #                     raw:
    #                       type: keyword
    #                       ignore_above: 256

beacons:
  service:
    elasticsearch:
      onchangeonly: True
    disable_during_state_run: True
