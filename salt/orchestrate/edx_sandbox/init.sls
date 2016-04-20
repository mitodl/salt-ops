ensure_instance_profile_exists_for_edx_sandbox_ami:
  boto_iam_role.present:
    - name: edx-sandbox-ami-instance-role

provision_edx_sandbox_ami:
  cloud.profile:
    - name: edx_sandbox_ami
    - profile: edx_sandbox_ami

resize_root_partitions_on_edx_sandbox_ami_node:
  salt.state:
    - tgt: 'G@roles:edx_sandbox and G@sandbox_status:ami-provision'
    - tgt_type: compound
    - sls: utils.grow_partition

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

build_edx_sandbox_ami_nodes:
  salt.state:
    - tgt: 'G@roles:edx_sandbox and G@sandbox_status:ami-provision'
    - tgt_type: compound
    - highstate: True
