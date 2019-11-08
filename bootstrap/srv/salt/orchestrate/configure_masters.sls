{% set aws_access_key = salt.sdb.get('sdb://osenv/AWS_ACCESS_KEY_ID') %}
{% set aws_secret_access_key = salt.sdb.get('sdb://osenv/AWS_SECRET_ACCESS_KEY') %}
{% set ENVIRONMENT = salt.sdb.get('sdb://osenv/ENVIRONMENT') %}

{% set prod_master = salt.cloud.get_instance('master-operations-production') %}
{% set qa_master = salt.cloud.get_instance('master-operations-qa') %}

{% do salt.log.debug('Current context is: ' ~ show_full_context()) %}

generate_roster_file:
  file.managed:
    - name: {{ tplpath.replace(tplfile, '') }}/../../../../../../etc/salt/roster
    - contents: |
        master-operations-production:
          host: {{ prod_master['public_ips'] }}
          user: admin
          sudo: True
        master-operations-qa:
          host: {{ qa_master['public_ips'] }}
          user: admin
          sudo: True

build_master_nodes:
  salt.state:
    - tgt: master-operations*
    - highstate: True
    - ssh: True
