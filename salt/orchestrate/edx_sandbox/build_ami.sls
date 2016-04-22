ensure_instance_profile_exists_for_edx_sandbox_ami:
  boto_iam_role.present:
    - name: edx-sandbox-ami-instance-role

provision_edx_sandbox_ami:
  cloud.profile:
    - name: edx_sandbox_ami
    - profile: edx_sandbox_ami

load_pillar_data_on_edx_sandbox_ami_node:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'G@roles:edx_sandbox and G@sandbox_status:ami-provision'
    - tgt_type: compound

populate_mine_with_edx_sandbox_ami_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:edx_sandbox and G@sandbox_status:ami-provision'
    - tgt_type: compound

build_edx_sandbox_ami_node:
  salt.state:
    - tgt: 'G@roles:edx_sandbox and G@sandbox_status:ami-provision'
    - tgt_type: compound
    - highstate: True

{% set ami_name = "edx_sandbox_ami_{}".format(None | strftime("%Y%m%d%H%M%S")) %}

create_edx_sandbox_ami_image:
  salt.function:
    - name: boto_ec2.create_image
    - tgt: master
    - arg:
      # Name of the AMI that will be created on AWS
      - {{ ami_name }}
    - kwarg:
        instance_name: edx_sandbox_ami

# This is a hack to get around the fact that there is neither an attribute for
# setting tags when using the boto_ec2.create_image module, nor a way to lazily
# evaluate templated salt states.
set_temp_master_grain_for_ami_name:
  salt.function:
    - name: grains.set
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
      - newest_edx_sandbox_ami
    - kwarg:
        val: {{ ami_name }}
