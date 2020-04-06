python_dependencies:
  python_libs:
    - testinfra
    - pyhocon

dremio:
  config:
    paths:
      dist: dremioS3:///mitodl-data-lake/dremio/
    services:
      coordinator:
        enabled: {{ 'dremio-operations-0-v1' == salt.grains.get('id') }}
        master:
          enabled: {{ 'dremio-operations-0-v1' == salt.grains.get('id') }}
      executor:
        enabled: {{ 'dremio-operations-0-v1' != salt.grains.get('id') }}
  core_site_config:
    configuration:
      property:
        - name: fs.dremioS3.impl
          value: com.dremio.plugins.s3.store.S3FileSystem
        - name: fs.s3a.aws.credentials.provider
          value: com.amazonaws.auth.InstanceProfileCredentialsProvider
