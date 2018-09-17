{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'mitx-qa') %}
{% set codename = salt.sdb.get('sdb://consul/edx_codename') %}
{% set release_number = salt.sdb.get('sdb://consul/edxapp-{}-{}-release-version'.format(ENVIRONMENT, codename)) %}
{% set app_ami_id = salt.boto_ec2.find_images(ami_name='edxapp_{}_{}_base_release_{}'.format(ENVIRONMENT, codename, release_number))[0] %}
{% set worker_ami_id = salt.boto_ec2.find_images(ami_name='edx_worker_{}_{}_base_release_{}'.format(ENVIRONMENT, codename, release_number))[0] %}
{% set instance_name = 'edxapp-{}-{}-base'.format(ENVIRONMENT, codename) %}
{% set worker_instance_name = 'edx-worker-{}-{}-base'.format(ENVIRONMENT, codename) %}

update_edxapp_ami_value:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: sdb.set
    - arg:
        - 'sdb://consul/edx_{{ ENVIRONMENT }}_{{ codename }}_ami_id'
        - '{{ app_ami_id }}'

update_edx_worker_ami_value:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: sdb.set
    - arg:
        - 'sdb://consul/edx_worker_{{ ENVIRONMENT }}_{{ codename }}_ami_id'
        - '{{ worker_ami_id }}'

destroy_edx_base_instance:
  cloud.absent:
    - name: {{ instance_name }}

destroy_edx_worker_base_instance:
  cloud.absent:
    - name: {{ worker_instance_name }}
