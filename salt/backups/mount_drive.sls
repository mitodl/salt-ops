format_backup_drive:
  blockdev.formatted:
    - name: /dev/xvdb
    - fs_type: ext4

mount_backup_drive:
  mount.mounted:
    - name: /backups
    - device: /dev/xvdb
    - fstype: ext4
    - mkmnt: True
    - opts: 'relatime,user'

create_backup_directory:
  file.directory:
    - name: /backups/tmp
    - makedirs: True
