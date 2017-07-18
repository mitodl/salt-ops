install_duplicity:
  pkg.installed:
    - pkgs:
        - duplicity
        - python-pip

install_duplicity_backend_requirements:
  pip.installed:
    - names:
        - boto3
        - boto

{% for service in salt.pillar.get('backups:enabled', []) %}
{% if service.get('pkgs') %}
install_packages_for_{{ service.title }}_backup:
  pkg.installed:
    - pkgs: {{ service.pkgs }}
{% endif %}
{% endfor %}

{% for service in salt.pillar.get('backups:enabled', []) %}
run_backup_for_{{ service.title }}:
  file.managed:
    - name: /backups/{{service.title}}_backup.sh
    - source: salt://backups/templates/backup_{{ service.name }}.sh
    - template: jinja
    - context:
        settings: {{ service.settings }}
    - parallel: True
  cmd.script:
    - name: salt://backups/templates/backup_{{ service.name }}.sh
    - template: jinja
    - context:
        settings: {{ service.settings }}
    - parallel: True
    - require_in:
        - event: wait_for_backups_to_complete
{% endfor %}

wait_for_backups_to_complete:
  file.touch:
    - name: /backups/backup_complete
