{% set edx_codename = salt.sdb.get('sdb://consul/edx_codename') %}
{% set release_number = salt.sdb.get('sdb://consul/edxapp-{}-release-version').format(edx_codename) %}
{% set app_ami_id = salt.boto_ec2.find_images(ami_name='edxapp_{}_base_release_{}'.format(edx_codename, release_number))[0] %}
{% set worker_ami_id = salt.boto_ec2.find_images(ami_name='edx_worker_{}_base_release_{}'.format(edx_codename, release_number))[0] %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'mitx-qa') %}
{% set instance_name = 'edxapp-base-{}'.format(ENVIRONMENT) %}
{% set worker_instance_name = 'edx-worker-base-{}'.format(ENVIRONMENT) %}

update_edxapp_ami_value:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: sdb.set
    - arg:
        - 'sdb://consul/edx_ami_id'
        - '{{ app_ami_id }}'

update_edx_worker_ami_value:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: sdb.set
    - arg:
        - 'sdb://consul/edx_worker_ami_id'
        - '{{ worker_ami_id }}'

destroy_edx_base_instance:
  cloud.absent:
    - name: {{ instance_name }}

destroy_edx_worker_base_instance:
  cloud.absent:
    - name: {{ worker_instance_name }}
