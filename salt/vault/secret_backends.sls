enable_transit_secret_backend:
  vault.secret_backend_enabled:
    - backend_type: transit
    - description: Backend to provide encryption, hashing, and randomness as a service

enable_mitx_aws_secret_backend:
  vault.secret_backend_enabled:
    - backend_type: aws
    - mount_point: aws-mitx
    - description: Backend to dynamically create IAM credentials
