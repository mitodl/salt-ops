include:
  - rabbitmq.service

extract_autocluster_plugin:
  archive.extracted:
    - name: /tmp/rabbitmq
    - source: https://github.com/aweber/rabbitmq-autocluster/releases/download/0.6.1/autocluster-0.6.1.tgz
    - source_hash: sha1=7199f4846ea87a1beab9b5e7a63af80124bc9f22
    - archive_format: tar
    - tar_options: xz
    - if_missing: /tmp/rabbitmq/plugins/autocluster-0.6.1.ez

install_rabbitmq_aws_rabbitmq_plugin:
  file.managed:
    - name: /usr/lib/rabbitmq/lib/rabbitmq_server-{{ salt.pillar.get('rabbitmq:overrides:version', '3.6.2-1').split('-')[0] }}/plugins/rabbitmq_aws-0.1.2.ez
    - source: /tmp/rabbitmq/plugins/rabbitmq_aws-0.1.2.ez
    - watch_in:
        - service: rabbitmq_service_running
    - require:
        - archive: extract_autocluster_plugin
  rabbitmq_plugin.enabled:
    - name: rabbitmq_aws
    - watch:
        - file: install_rabbitmq_aws_rabbitmq_plugin
    - watch_in:
        - service: rabbitmq_service_running

install_autocluster_rabbitmq_plugin:
  file.managed:
    - name: /usr/lib/rabbitmq/lib/rabbitmq_server-{{ salt.pillar.get('rabbitmq:overrides:version', '3.6.2-1').split('-')[0] }}/plugins/autocluster-0.6.1.ez
    - source: /tmp/rabbitmq/plugins/autocluster-0.6.1.ez
    - watch_in:
        - service: rabbitmq_service_running
    - require:
        - archive: extract_autocluster_plugin
  rabbitmq_plugin.enabled:
    - name: autocluster
    - watch:
        - file: install_autocluster_rabbitmq_plugin
    - watch_in:
        - service: rabbitmq_service_running
    - require:
        - rabbitmq_plugin: install_rabbitmq_aws_rabbitmq_plugin
