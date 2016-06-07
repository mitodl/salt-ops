{% macro set_ami_status(image_id, ami_status) -%}
set_status_for_edx_sandbox_ami_{{ image_id }}:
  salt.function:
    - name: saltutil.runner
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
      - cloud.action
    - kwarg:
        func: ec2.set_tags
        kwargs:
          resource_id: ami_id
          ami_status: {{ ami_status }}
{%- endmacro %}

{%
  for image_id in salt['boto_ec2.find_images'](tags='{"ami_status": "active", "role": "edx_sandbox"}'):
    set_ami_status(image_id, 'inactive')

  set new_ami_name = salt['grains.get']('newest_edx_sandbox_ami')
  set new_ami_id = salt['boto_ec2.find_images'](ami_name=ami_name)

  set_ami_status(new_ami_id, 'active')
%}

destroy_edx_sandbox_ami_node:
  salt.function:
    - name: cloud.absent
    - tgt: 'roles:master'
    - tgt_type: grain
    - kwarg:
        name: edx_sandbox_ami

remove_temp_master_grain_for_ami_name:
  salt.function:
    - name: grains.delval
    - tgt: 'roles:master'
    - tgt_type: grain
    - arg:
      - newest_edx_sandbox_ami
    - kwarg:
        destructive: True
