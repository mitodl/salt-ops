{% set devicename = salt.grains.get('ec2:block_device_mapping:root') %}
{% set part_number = 1 %}

install_parted:
  pkg.installed:
    - name: parted
    - refresh: True

resize_root_partition:
  cmd.run:
    - name: parted {{ devicename }} resizepart {{ part_number }} yes 100%

resize_file_system:
  cmd.run:
    - name: resize2fs {{ devicename }}{{ part_number }}
