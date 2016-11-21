backup_host:
  provider: mitx
  size: t2.micro
  image: ami-c8bda8a2
  ssh_username: admin
  ssh_interface: private_ips
  script_args: -U -Z -A salt.private.odl.mit.edu
  iam_profile: backups-instance-role
  tag:
    role: backups
  grains:
    roles:
      - backups
  block_device_mappings:
    - DeviceName: /dev/xvda
      Ebs.VolumeSize: 400
      Ebs.VolumeType: gp2
