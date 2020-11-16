{% set data_path = '/tmp/edx_config' -%}
{% set venv_path = '/tmp/edx_config/venv' -%}
{% set repo_path = '/tmp/edx_config/configuration' -%}
{% set conf_file = '/tmp/edx_config/edx-sandbox.conf' -%}
{% set git_export_path = salt.pillar.get('edxapp:EDXAPP_GIT_REPO_EXPORT_DIR',
                                         '/edx/var/edxapp/export_course_repos') -%}
{% set git_servers = salt.pillar.get('edx:ssh_hosts',
                                     [{'name': 'github.com',
                                       'fingerprint': '9d:38:5b:83:a9:17:52:92:56:1a:5e:c4:d4:81:8e:0a:ca:51:a2:64:f1:74:20:11:2e:f8:8a:c3:a1:39:49:8f'},
                                      {'name': 'github.mit.edu',
                                       'fingerprint': 'aa:d2:e9:66:7e:46:77:d3:7d:d9:39:3f:f4:9f:17:a1:18:c1:87:8f:69:cb:8f:d0:db:10:b7:71:5e:ad:57:68'}]) %}
{% set theme_repo = salt.pillar.get('edx:edxapp:custom_theme:repo', 'https://github.com/mitodl/mitx-theme') -%}
{% set theme_name = salt.pillar.get('edx:edxapp:THEME_NAME', None) -%}
{% set theme_branch = salt.pillar.get('edx:edxapp:custom_theme:branch', 'mitx') -%}
{% set theme_dir = salt.pillar.get('edx:edxapp:EDXAPP_COMPREHENSIVE_THEME_DIR', '/edx/app/edxapp/themes') -%}
{% set os_packages = salt.pillar.get('edx:dependencies:os_packages',
                                     ['git',
                                      'libmysqlclient-dev',
                                      'mariadb-client-10.0',
                                      'landscape-common',
                                      'libssl-dev',
                                      'python3-dev',
                                      'python3-pip',
                                      'python3-virtualenv',
                                      'nfs-common',
                                      'postfix',
                                      'memcached']) -%}

include:
  - .run_ansible

install_os_packages:
  pkg.installed:
    - pkgs: {{ os_packages|tojson }}
    - refresh: True
    - refresh_modules: True
    - require_in:
        - virtualenv: create_ansible_virtualenv
        - git: clone_edx_configuration

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


{# BEGIN states that do not apply to "sandbox" and "devstack" ... #}
{% if not ('sandbox' in salt.grains.get('roles')) %}

{% set device_name = '{}.{}.efs.us-east-1.amazonaws.com:/'.format(salt.grains.get('ec2:availability_zone', 'us-east-1b'), salt.pillar.get('edx:efs_id')) %}
{% set fstab_contents = salt.mount.fstab() %}
{% for fmount, settings in fstab_contents.items() %}
{% if fmount == '/mnt/data' and settings.fstype == 'nfs4' and settings.device != device_name %}
remove_{{ settings.device }}_mount_config_from_fstab:
  mount.unmounted:
    - name: {{ fmount }}
    - device: {{ settings.device }}
    - persist: True
{% endif %}
{% endfor %}

mount_efs_filesystem_for_course_assets:
  mount.mounted:
    - name: /mnt/data
    - device: {{ salt.grains.get('ec2:availability_zone', 'us-east-1b')|trim }}.{{ salt.pillar.get('edx:efs_id')|trim }}.efs.us-east-1.amazonaws.com:/
    - fstype: nfs4
    - mkmnt: True
    - persist: True
    - mount: True

create_course_asset_symlink:
  file.symlink:
    - name: /edx/var/edxapp/course_static
    - target: {{ salt.pillar.get('edx:edxapp:GIT_REPO_DIR', '/mnt/data/prod_repos') }}
    - makedirs: True
    - force: True
    - user: edxapp
    - group: www-data

create_edxapp_data_dir_symlink:
  file.symlink:
    - name: /edx/app/edxapp/data
    - target: {{ salt.pillar.get('edx:edxapp:GIT_REPO_DIR', '/mnt/data/prod_repos') }}
    - makedirs: True
    - force: True
    - user: edxapp
    - group: www-data
    - require:
        - cmd: run_ansible

{# Steps to enable git export for courses #}
make_git_export_directory:
  file.directory:
    - name: {{ git_export_path }}
    - user: www-data
    - group: www-data
    - makedirs: True

add_private_ssh_key_to_www-data_for_git_export:
  file.managed:
    - name: /var/www/.ssh/id_rsa
    - contents_pillar: edx:ssh_key
    - mode: 0600
    - makedirs: True
    - dir_mode: 0700
    - user: www-data
    - group: www-data

{% endif %}
{# END states that do not apply to "sandbox" and "devstack" ... #}

{% if theme_name %}
install_edxapp_theme:
  file.directory:
    - name: {{ theme_dir }}
    - makedirs: True
    - user: edxapp
    - group: edxapp
  git.latest:
    - name: {{ theme_repo }}
    - branch: {{ theme_branch }}
    - rev: {{ theme_branch }}
    - target: {{ theme_dir }}/{{ theme_name }}
    - user: edxapp
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True
    - require:
      - file: install_edxapp_theme
    - require_in:
      - cmd: run_ansible
{% endif %}

{% for host in git_servers %}
add_{{ host.name }}_to_known_hosts_for_edxapp:
  ssh_known_hosts.present:
    - name: {{ host.name }}
    - user: www-data
    - enc: ssh-rsa
    - fingerprint: "{{ host.fingerprint }}"
    - fingerprint_hash_type: sha256
{% endfor %}
