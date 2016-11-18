install_duplicity:
  pkg.installed:
    - pkgs:
        - duplicity
        - python-pip

install_duplicity_backend_requirements:
  pip.installed:
    - name: boto

{% for service in salt.pillar.get('backups:enabled', []) %}
install_packages_for_{{ service.title }}_backup:
  pkg.installed:
    - pkgs: {{ service.pkgs }}

run_backup_for_{{ service.title }}:
  cmd.script:
    - name: salt://backups/templates/{{ service.name }}.sh
    - template: jinja
    - context:
        settings: {{ service.settings }}
{% endfor %}
