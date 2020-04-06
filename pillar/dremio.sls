{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set zk_release_id = salt.sdb.get('sdb://consul/zookeeper/' ~ ENVIRONMENT ~ '/release-id') %}
{% if not zk_release_id %}
{% set zk_release_id = 'v1' %}
{% endif %}


python_dependencies:
  python_libs:
    - testinfra
    - pyhocon

dremio:
  config:
    {% if 'dremio-operations-0-v1' == salt.grains.get('id') %}
    paths:
      dist: dremioS3:///mitodl-data-lake/dremio/
    {% endif %}
    services:
      coordinator:
        enabled: {{ 'dremio-operations-0-v1' == salt.grains.get('id') }}
        master:
          enabled: {{ 'dremio-operations-0-v1' == salt.grains.get('id') }}
      executor:
        enabled: {{ 'dremio-operations-0-v1' != salt.grains.get('id') }}
    zookeeper: zookeeper-{{ ENVIRONMENT }}-0-{{ zk_release_id }}.zookeeper.service.consul:2181,zookeeper-{{ ENVIRONMENT }}-1-{{ zk_release_id }}.zookeeper.service.consul:2181,zookeeper-{{ ENVIRONMENT }}-2-{{ zk_release_id }}.zookeeper.service.consul:2181
  core_site_config:
    configuration:
      property:
        - name: fs.dremioS3.impl
          value: com.dremio.plugins.s3.store.S3FileSystem
        - name: fs.s3a.aws.credentials.provider
          value: com.amazonaws.auth.InstanceProfileCredentialsProvider
