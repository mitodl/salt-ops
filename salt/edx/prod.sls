{% set data_path = '/tmp/edx_config' %}
{% set venv_path = '/tmp/edx_config/venv' %}
{% set repo_path = '/tmp/edx_config/configuration' %}
{% set conf_file = '/tmp/edx_config/edx-sandbox.conf' %}

install_os_packages:
  pkg.installed:
    - pkgs:
       - git
       - libmysqlclient-dev
       - python2.7
       - python-dev
       - python-pip
       - python-virtualenv
       - nfs-common
       - postfix
    - refresh: True
    - refresh_modules: True

clone_edx_configuration:
  file.directory:
    - name: {{ repo_path }}
    - makedirs: True
  git.latest:
    - name: {{ salt.pillar.get('edx:config:repo', 'https://github.com/edx/configuration.git') }}
    - rev: {{ salt.pillar.get('edx:config:branch', 'named-release/dogwood.3') }}
    - target: {{ repo_path }}
    - user: root
    - require:
      - file: clone_edx_configuration

mark_ansible_as_editable:
  file.replace:
    - name: {{ repo_path }}/requirements.txt
    - pattern: |
        ^git\+https://github\.com/edx/ansible.*
    - repl: |
        --editable git+https://github.com/edx/ansible.git@stable-1.9.3-rc1-edx#egg=ansible==1.9.3-edx
    - require:
      - git: clone_edx_configuration

create_ansible_virtualenv:
  # Note: We need to use a virtualenv over here because the Salt minion bootstrap
  #       installs some OS `python-` packages that are also pulled in by the edX
  #       config requirements for Ansible (e.g. python-jinja). This causes python
  #       package metadata issues, resulting in Ansible not being able to import
  #       dependencies at runtime.
  virtualenv.managed:
    - name: {{ venv_path }}
    - requirements: {{ repo_path }}/requirements.txt
    - require:
      - git: clone_edx_configuration
      - pkg: install_os_packages

place_ansible_environment_configuration:
  file.managed:
    - name: {{ conf_file }}
    - source: salt://edx/templates/ansible_env_config.yml.j2
    - template: jinja
    - makedirs: True

{% if salt.pillar.get('edx:generate_tls_certificate') %}
generate_self_signed_certificate:
  module.run:
    - name: tls.create_self_signed_cert
    - CN: {{ salt.pillar.get('edx:ansible_env_config:TLS_KEY_NAME') }}
    - replace: True
    - require_in:
      - cmd: run_ansible
{% else %}
{%
  set key_path = '{}/{}'.format(
    salt.pillar.get('edx:edxapp:TLS_LOCATION'),
    salt.pillar.get('edx:edxapp:TLS_KEY_NAME')
  )
%}
{% for ext in ['crt', 'key'] %}
place_tls_{{ ext }}_file:
  file.managed:
    - name: {{ key_path }}.{{ ext }}
    - contents_pillar: {{ 'edx:tls_{}'.format(ext) }}
    - user: root
    - group: root
    - mode: 600
    - makedirs: True
    - require_in:
      - cmd: run_ansible
{% endfor %}
{% endif %}

mount_efs_filesystem_for_course_assets:
  mount.mounted:
    - name: /mnt/data
    - device: {{ salt.grains.get('ec2:availability_zone', 'us-east-1b')|trim }}.{{ salt.pillar.get('edx:efs_id')|trim }}.efs.us-east-1.amazonaws.com:/
    - fstype: nfs4
    - mkmnt: True
    - persist: True
    - mount: True

run_ansible:
  cmd.script:
    - name: {{ data_path }}/run_ansible.sh
    - source: salt://edx/templates/run_ansible.sh.j2
    - template: jinja
    - cwd: {{ repo_path }}/playbooks
    - context:
        data_path: {{ data_path }}
        venv_path: {{ venv_path }}
        repo_path: {{ repo_path }}
        conf_file: {{ conf_file }}
        playbooks: {{ salt.pillar.get('edx:playbooks', ['edx-east/common.yml', 'edx-east/forum.yml',
                      'edx-east/xqueue.yml', 'edx-east/xqwatcher.yml',  'edx-east/edxapp.yml',
                      'edx-east/worker.yml']) }}
    - require:
      - virtualenv: create_ansible_virtualenv
