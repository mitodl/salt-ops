{% set data_path = '/tmp/edx_config' -%}
{% set venv_path = '/tmp/edx_config/venv' -%}
{% set repo_path = '/tmp/edx_config/configuration' -%}
{% set conf_file = '/tmp/edx_config/edx-vars.conf' -%}

{% set playbooks = salt.pillar.get('edx:playbooks', ['edx-east/edxapp.yml',
                                                     'edx-east/xqueue.yml',
                                                     'edx-east/forum.yml']) -%}

clone_edx_configuration:
  file.directory:
    - name: {{ repo_path }}
    - makedirs: True
  git.latest:
    - name: {{ salt.pillar.get('edx:config:repo', 'https://github.com/edx/configuration.git') }}
    - rev: {{ salt.pillar.get('edx:config:branch', 'open-release/eucalyptus.master') }}
    - target: {{ repo_path }}
    - user: root
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - require:
      - file: clone_edx_configuration

mark_ansible_as_editable:
  file.replace:
    - name: {{ repo_path }}/requirements.txt
    - pattern: |
        ^git\+https://github\.com/edx/ansible.*
    - repl: |
        -e git+https://github.com/edx/ansible.git@stable-1.9.3-rc1-edx#egg=ansible==1.9.3-edx
    - require:
        - git: clone_edx_configuration

replace_nginx_static_asset_template_fragment:
  file.managed:
    - name: {{ repo_path }}/playbooks/roles/nginx/templates/edx/app/nginx/sites-available/static-files.j2
    - source: salt://edx/files/nginx_static_assets.j2
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
      - file: replace_nginx_static_asset_template_fragment

place_ansible_environment_configuration:
  file.managed:
    - name: {{ conf_file }}
    - contents: |
        {{ salt.pillar.get('edx:ansible_vars')|yaml(False)|indent(8) }}
    - makedirs: True

{# Creating the edxapp user here so that it is present for setting appropriate
   file and directory ownership #}
create_edxapp_user:
  user.present:
    - name: edxapp
    - home: /edx/app/edxapp
    - createhome: False
    - shell: /bin/false

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
        playbooks: {{ playbooks }}
        extra_flags: "{{ salt.pillar.get('edx:ansible_flags', ' ') }}"
    - require:
      - virtualenv: create_ansible_virtualenv
    - unless: {{ salt.pillar.get('edx:skip_ansible', False) }}
