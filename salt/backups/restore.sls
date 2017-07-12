install_duplicity:
  pkg.installed:
    - pkgs:
        - duplicity
        - python-pip

install_duplicity_backend_requirements:
  pip.installed:
    - name: boto

{% for service in salt.pillar.get('restores', []) %}
{% if service.get('pkgs') %}
install_packages_for_{{ service.title }}_backup:
  pkg.installed:
    - pkgs: {{ service.pkgs }}
{% endif %}

run_restore_for_{{ service.title }}:
  file.managed:
    - name: /backups/{{service.title}}_restore.sh
    - source: salt://backups/templates/restore_{{ service.name }}.sh
    - template: jinja
    - context:
        settings: {{ service.settings }}
  cmd.script:
    - name: salt://backups/templates/restore_{{ service.name }}.sh
    - template: jinja
    - context:
        settings: {{ service.settings }}
{% endfor %}
