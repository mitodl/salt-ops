{% set release_number = salt.sdb.get('sdb://consul/edxapp-release-version') %}
{% set app_ami_id = salt.boto_ec2.find_images(ami_name='edxapp_base_release_{}'.format(release_number)) %}
{% set worker_ami_id = salt.boto_ec2.find_images(ami_name='edx_worker_base_release_{}'.format(release_number)) %}

update_edxapp_ami_value:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: sdb.set
    - arg:
        - sdb://consul/edx_ami_id
        - {{ app_ami_id }}

update_edx_worker_ami_value:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: sdb.set
    - arg:
        - sdb://consul/edx_worker_ami_id
        - {{ worker_ami_id }}
