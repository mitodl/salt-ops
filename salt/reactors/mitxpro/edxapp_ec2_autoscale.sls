{% set payload = data['message']|load_json %}
{% set instanceid = payload['Message']|load_json %}
{% set ENVIRONMENT = 'mitxpro-production' %}
{% set PURPOSE = 'xpro-production' %}
{% set env_dict = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set env_settings = env_dict.environments[ENVIRONMENT] %}
{% set purposes = env_settings.purposes %}
{% set edx_codename = purposes[PURPOSE].versions.codename %}
{% set ami_id = salt.sdb.get('sdb://consul/edx_{}_{}_ami_id'.format(ENVIRONMENT, edx_codename)) %}
{% set release_number = salt.sdb.get('sdb://consul/edxapp-{}-{}-release-version'.format(ENVIRONMENT, edx_codename))|int %}
{% set business_unit = 'mitxpro' %}

{% if 'Event' in payload['Message'] %}
{% if 'LAUNCH' in payload['Message'] %}
ec2_autoscale_launch:
  runner.cloud.create:
    - provider: mitx
    - instance_id: {{ instanceid['EC2InstanceId'] }}
    - image: {{ ami_id }}
    - ssh_interface: private_ips
    - ssh_username: ubuntu
    - wait_for_ip_interval: 60
    - wait_for_passwd_maxtries: 60
    {% if 'edx-worker' in payload['Message'] %}
    - instances: edx-worker-{{ ENVIRONMENT }}-xpro-production-{{ instanceid['EC2InstanceId'].strip('i-') }}
    - grains:
        roles:
          - edx-worker
        environment: {{ ENVIRONMENT }}
        purpose: {{ PURPOSE }}
        business_unit: {{ business_unit }}
        release_number: {{ release_number}}
        edx_codename: {{ edx_codename }}
    {% else %}
    - instances: edx-{{ ENVIRONMENT }}-xpro-production-{{ instanceid['EC2InstanceId'].strip('i-') }}
    - grains:
        roles:
          - edx
        environment: {{ ENVIRONMENT }}
        purpose: {{ PURPOSE }}
        business_unit: {{ business_unit }}
        release_number: {{ release_number}}
        edx_codename: {{ edx_codename }}
    {% endif %}

{% elif 'TERMINATE' in payload['Message'] %}
remove_key:
  wheel.key.delete:
    - match: edx-{{ ENVIRONMENT }}-xpro-production-{{ instanceid['EC2InstanceId'].strip('i-') }}
{% endif %}
{% endif %}
