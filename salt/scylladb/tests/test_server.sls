verify_data_drive_is_present:
  testinfra.mount_point:
    - name: /var/lib/scylla
    - exists: True
    - filesystem:
        expected: xfs
        comparison: eq
