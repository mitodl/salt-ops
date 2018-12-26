{% set ENVIRONMENT = salt.grains.get('environment') %}

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
schedule_backups_for_{{ service.title }}:
  file.managed:
    - name: /backups/{{service.title}}_backup.sh
    - source: salt://backups/templates/backup_{{ service.name }}.sh
    - template: jinja
    - context:
        settings: {{ service.settings }}
        ENVIRONMENT: {{ ENVIRONMENT }}
        title: {{ service.title }}
  cron.present:
    - name: /backups/{{ service.title }}_backup.sh
    - minute: 0
    - hour: 0
    - identifier: backup_{{ service.title }}
{% endfor %}
