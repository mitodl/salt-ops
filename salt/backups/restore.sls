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

{% for service in salt.pillar.get('restores', []) %}
{% if service.get('pkgs') %}
install_packages_for_{{ service.title }}_backup:
  pkg.installed:
    - pkgs: {{ service.pkgs|tojson }}
{% endif %}
{% endfor %}

{% for service in salt.pillar.get('restores', []) %}
run_restore_for_{{ service.title }}:
  file.managed:
    - name: /backups/{{service.title}}_restore.sh
    - source: salt://backups/templates/restore_{{ service.name }}.sh
    - template: jinja
    - context:
        settings: {{ service.settings|tojson }}
  cmd.script:
    - name: salt://backups/templates/restore_{{ service.name }}.sh
    - template: jinja
    - context:
        settings: {{ service.settings|tojson }}
    - fire_event: restore/{{ ENVIRONMENT }}/{{ service.title }}
{% endfor %}

wait_for_restores_to_complete:
  file.touch:
    - name: /backups/restore_complete
    - order: last
