{% set payload = data['message']|load_json %}
{% set instanceid = payload['Message']|load_json %}
{% set ENVIRONMENT = 'mitxpro-production' %}

edxapp_highstate:
  local.state.sls:
    - tgt: 'edx-{{ ENVIRONMENT }}-xpro-production-{{ instanceid['EC2InstanceId'].strip('i-') }}'
    - queue: True
    - arg:
        - edx.prod
    - kwargs:
        pillar:
          edx:
            ansible_flags: '--tags install:configuration'
