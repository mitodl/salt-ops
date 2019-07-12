{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ENVIRONMENT = salt.environ.get('ENVIRONMENT', 'mitx-qa') %}
{% set env_data = env_settings.environments[ENVIRONMENT] %}
{% set PURPOSE = salt.environ.get('PURPOSE', 'current-residential-draft') %}
{% set VPC_NAME = env_data.vpc_name %}
{% set BUSINESS_UNIT = salt.environ.get('BUSINESS_UNIT', env_data.business_unit) %}
{% set launch_date = salt.status.time(format="%Y-%m-%d") %}
{% set subnet_ids = salt.boto_vpc.describe_subnets(
    vpc_id=salt.boto_vpc.describe_vpcs(
        name=env_data.vpc_name).vpcs[0].id
    ).subnets|map(attribute='id')|list|sort(reverse=True) %}
{% set ANSIBLE_FLAGS = salt.environ.get('ANSIBLE_FLAGS') %}

load_edx_cloud_profile:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/edx.conf
    - source: salt://orchestrate/aws/cloud_profiles/edx.conf
    - template: jinja

generate_analytics_edx_cloud_map_file:
  file.managed:
    - name: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_analytics_edx_map.yml
    - source: salt://orchestrate/aws/map_templates/analytics_edx.yml
    - template: jinja
    - makedirs: True
    - context:
        business_unit: {{ BUSINESS_UNIT }}
        environment_name: {{ ENVIRONMENT }}
        purpose: {{ PURPOSE }}
        securitygroupids:
          edxapp: {{ salt.boto_secgroup.get_group_id(
              'edx-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          edx-worker: {{ salt.boto_secgroup.get_group_id(
              'edx-worker-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          default: {{ salt.boto_secgroup.get_group_id(
              'default', vpc_name=VPC_NAME) }}
          salt-master: {{ salt.boto_secgroup.get_group_id(
            'salt_master-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          public-ssh: {{ salt.boto_secgroup.get_group_id(
            'public-ssh-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
          consul-agent: {{ salt.boto_secgroup.get_group_id(
            'consul-agent-{}'.format(ENVIRONMENT), vpc_name=VPC_NAME) }}
        subnetids: {{ subnet_ids|tojson }}
        tags:
          launch-date: '{{ launch_date }}'
          Department: {{ BUSINESS_UNIT }}
          OU: {{ BUSINESS_UNIT }}
          Environment: {{ ENVIRONMENT }}
    - require:
        - file: load_edx_cloud_profile

ensure_instance_profile_exists_for_edx:
  boto_iam_role.present:
    - name: edx-instance-role

deploy_analytics_edx_cloud_map:
  salt.function:
    - tgt: 'roles:master'
    - tgt_type: grain
    - name: saltutil.runner
    - arg:
        - cloud.map_run
    - kwarg:
        path: /etc/salt/cloud.maps.d/{{ ENVIRONMENT }}_analytics_edx_map.yml
    - require:
        - file: generate_analytics_edx_cloud_map_file

sync_external_modules_for_edx_nodes:
  salt.function:
    - name: saltutil.sync_all
    - tgt: 'P@roles:edx-analytics and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound

load_pillar_data_on_edx_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'P@roles:edx-analytics and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: deploy_analytics_edx_cloud_map

populate_mine_with_edx_node_data:
  salt.function:
    - name: mine.update
    - tgt: 'P@roles:edx-analytics and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: load_pillar_data_on_edx_nodes

{# Reload the pillar data to update values from the salt mine #}
reload_pillar_data_on_edx_nodes:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: 'P@roles:edx-analytics and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - require:
        - salt: populate_mine_with_edx_node_data

{# Deploy Consul agent first so that the edx deployment can use provided DNS endpoints #}
deploy_consul_agent_to_analytics_nodes:
  salt.state:
    - tgt: 'P@roles:edx-analytics and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - sls:
        - consul
        - consul.dns_proxy

build_analytics_node:
  salt.state:
    - tgt: 'P@roles:edx-analytics and G@environment:{{ ENVIRONMENT }}'
    - tgt_type: compound
    - highstate: True
    - require:
        - salt: deploy_consul_agent_to_analytics_nodes

create_user_account:
  salt.function:
    - tgt: 'G@roles:edx-analytics and G@environment:mitx-production'
    - tgt_type: compound
    - name: user.add
    - kwarg:
        name: ichuang
        home: /home/ichuang
        groups:
          - sudo
          - edxapp

{% for pubkey in ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCDegFnWcIrLwQLUlSEhfY1KZyJAt//Uzn3k5RUSBC/E8kzznxnMPPUN+D42Gwf/Y3aZxplL7WMqE6hu7L7ANsSVnkCBy63ZsUmA0p4owiYlad8NDlhNxYfEEtmqDDE1g0Uqv5X+1HkcKOWxvqjGWVUzxndSQZRaAgtjzWVmOdWrIpNFM3iEO8mKe3d9wTg+iEk4TPVq7U22dLwwtBT0axjzdDVvyEu0zl8diyUJNZmzp+AK+Q56LAMi72/pnBvxV4kYBvLNvxaGc+wEigv10v3EGqWPVA10rDulBjzF4DHOQogCOBxEDPDhQXnyYRTRmclcwB262HA/4JlyslxkGw7 ocw-chuang',
        'ssh-dss AAAAB3NzaC1kc3MAAACBAI70pqMzB9oN23EL51ByF0/GYxNI3R9G6IV1rjOPls7FzWNITmlAm0UEyHRR7P+jveCqFRd1uj+Fb05yBXUmL+cVQl1JnG3G6fwChop9q18yynngZrD3balzVe0x27gnhMUdqPjaDo3SufwqM3pWVjYY9PdNuzxwzh/MrewuZivPAAAAFQDAA2qMBUcHsu1r0lW356ncf0V0mQAAAIBiqw6ENw3q9VXQv7x4MHs5G1xqUV8sUOugD+ZoZ5nzZJtgAJrjX4XnVO+1xxjVbCSbpiw8Jyxu0Zl3akeI/x9+j6qKE3zKPfNgtBJhITZLA01w5Z1wMvJ51z6gWvyXLDxmePC1AM/9ZyhYewWztGy94mePFmRuCauURQTUIJZL6wAAAIAzbih1fNn7lS/y5Agt7lxf4My1B/TGbFRpsoSV35Dvt7zIlwHUdG8FcrqRIamFV3c3Gb42zcDruDvuinrtIIgXXGEQ167SUALoID1e7MBiK4SUWIrhYLC7BpcFl3rM21cwJawPgFtsMVPn7pzOUkUXsMWED/u3/OtI7rmDnSHMDA== ike@f',
        'ssh-dss AAAAB3NzaC1kc3MAAACBANr+McQzQGhseUuBGjjgNKiWCVybt9074lgZhkg4RJ1YVEwzBairR4r9jFPZQ++rS/FqOADloTyfG4wzaQoszefZv/KpFu8vn1HFi3ZvEn699syBbcM8RbSsR2RhtosqcyAFi/qvJyqL54WgR52VBJ4y55kma1FE7LrHgQ5lDP4xAAAAFQDowE/0SswsfGJ9IDnl2pj4U4r87QAAAIEA1E8KW08oSyVibmcZVyGibqrlkMb1Feyrl79icvr1MgPserBYliqN+qkMCxTqobHBAYARLqLrDKte7K8HmCa98Ri06XRYUNF/lRKOOfoupFV4H4xP5dTNrNu2nqU0Rk/EHmsU1492nbNcdifY4cj8YC64htI+hu+bYKH7gsGiFNUAAACALZCPQOvKLOpHOXgRJQHLlLA+UDiVHzL/bcKtaDw8pTerU9jUIeOSF03SszyzViW52x8x8q0rr18IrqaRLB14LeV6wo5kRu4JYgp3JrizA4Bt9YVm+7v9s5dgL8hk9Bkju4ZqskymuXCaRatT+pDUbhoeNi0qSPOofH0lNQ6mtNI= ike@te',
        'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxNgkS88ONPJiHPF9CkgD06NjHoXznX63XX+rGFUs+X1EbPChqA+41ysr64goulhEamwzDOCZhWm+mdcks3ZT7drc523BrjSH/oVE8MZCTBa3k1z/l1G9iGqeDqsYkcD2DTPFRuXLZLVjfJSE3eaXNFFUGWXHQcOfupGrz2nNBdAreRBbjRy0ZO9geWAP9l9b7QPEncY1rctd8cyrSsP2Iz/zkt7bxV7kcdQb2BpN7HBICfmW8TwTC68pvLzBsZHd6QLqOHySJ+LgAhs17eBGooDiX1i6Sk6uKgOJtA/8v+Z6EAb1dk5LNT/6P5y8VmLjHCbc/KnAmllfq6sajBeKFQ== ike@tea',
        'ssh-dss AAAAB3NzaC1kc3MAAACBAM9M8k5XDx88567Y2jxlg/zRcHUVHk42v9xWLBJY4G4VwBmhiWtQzfqX/+PuW7F5ipLR3WHmcsSBSKYN6V2QNKisURLm+PHbOVfbcJ8WfCQDxJgwTSuVdu1terltqYNPj9OOAsm9jz+cn58FOh0lM4Mv2GGsoMM9rllLpXyFi77nAAAAFQCyEIIyfbbkDUekiong0fFlG+Y1TQAAAIBYbHVio+mNdCjL3DkwJyHRvHqlFIKbFfCbkUBqM62hnipjWytOC0P9AdH3cZwYRCo1AAh3QAI0p/hTTUHYyG6WyUcXMx5KaZqgxq+l3Be5xMzEoIj8nCU2XJNko5A2ia6WkEp700U/GHKQyyz6bj5tueQusT1NofaP3O/Y8ZAaYAAAAIEAvhea37T06IcTlCEzKdQ5qiObYJgNwVqroCSJ3DV5SMNZkYSLiqSXADg4eWKYILivOqevSxCTwv+fWOiPwZ4MKkHtCAksQ9VPEspONm6nSrsgnC11m1DrVZVx3i/4bI71sp3wIz6HhsC0R9dTKcPXDu2RV3x18Bpf7YxggZer5kc= ike@ikes',
        'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEArqmhtieZKYvRqzHvNVCzvQXbXqVXJXuARb8PXkgCsBrDKpxfVjYhd6Uwt+4K/OAgUpPRABBg5uKdFPDEIFxEMZwZfZfj2Tk3wFtDHs/z1ravwdUVrR+0WBP1Gqn/rmfrsqHRKNwaHD+DHeIWI7FvRQxHV8s1YZgzzZVC0hHKh24bSwynDtVBstT7uiQ+oZMyqtyYNH+tnRBNdlB/2xeK4grA7J7aCR5k6agfVG7WlMCTKIZr4ej3WUfCffjstz8CcBVNPb1dfTN8oHC9kgRj0BCeiLH8Xj1o1rFO58P+HiuvGcKbZzRgymNe5EnoY3OpoP6s95te3Ll73AEIJEX+bQ== ike@route'] %}
{% set enc, key, comment = pubkey.split() %}
add_{{ comment }}_public_key_to_user:
  salt.function:
    - tgt: 'G@roles:edx-analytics and G@environment:mitx-production'
    - tgt_type: compound
    - name: ssh.set_auth_key
    - kwarg:
        user: ichuang
        enc: {{ enc }}
        key: {{ key }}
        comment: {{ comment }}
{% endfor %}
