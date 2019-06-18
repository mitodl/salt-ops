{% set payload = data['message']|load_json %}
{% set instanceid = payload['Message']|load_json %}
{% set ENVIRONMENT = 'mitxpro-production' %}
{% set PURPOSE = 'xpro-production' %}
{% set env_dict = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set env_settings = env_dict.environments[ENVIRONMENT] %}
{% set purposes = env_settings.purposes %}
{% set edx_codename = purposes[PURPOSE].versions.codename %}
{% set ami_id = salt.sdb.get('sdb://consul/edx_{}_{}_ami_id'.format(ENVIRONMENT, edx_codename)) %}

{% if 'Event' in payload['Message'] %}
{% if 'LAUNCH' in payload['Message'] %}
ec2_autoscale_launch:
  runner.cloud.create:
    - provider: mitx
    - instances: edx-{{ ENVIRONMENT }}-xpro-production-{{ instanceid['EC2InstanceId'].strip('i-') }}
    - instance_id: {{ instanceid['EC2InstanceId'] }}
    - image: {{ ami_id }}
{% elif 'TERMINATE' in payload['Message'] %}
remove_key:
  wheel.key.delete:
    - match: edx-{{ ENVIRONMENT }}-xpro-production-{{ instanceid['EC2InstanceId'].strip('i-') }}
{% endif %}
{% endif %}
