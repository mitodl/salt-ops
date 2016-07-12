{% set devicename = salt.grains.get('ec2:block_device_mapping:root') %}
{% set part_number = salt.pillar.get('system_settings:os_parition_num', 2) %}

install_parted:
  pkg.installed:
    - name: parted
    - refresh: True

resize_root_partition:
  cmd.run:
    - name: echo "resizepart {{ part_number }} yes 100%\n" | parted {{ devicename }}

resize_file_system:
  cmd.run:
    - name: resize2fs {{ devicename }}{{ part_number }}
