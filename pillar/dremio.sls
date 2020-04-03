dremio:
  config:
    paths:
      dist: dremioS3:///mitodl-data-lake/dremio/accel
  core_site_config:
    configuration:
      property:
        - name: fs.dremioS3.impl
          value: com.dremio.plugins.s3.store.S3FileSystem
        - name: fs.s3a.aws.credentials.provider
          value: com.amazonaws.auth.InstanceProfileCredentialsProvider
