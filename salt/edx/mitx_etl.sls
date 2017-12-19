install_python3_pip:
  pkg.installed:
    - pkgs:
        - python3
        - python3-pip
    - refresh: True
    - require:
      - pkg: install_python_3

create_mitx_directory:
  file.directory:
    - name: /mitx

clone_mitx_etl_repo:
  git.latest:
    - name: https://github.com/mitodl/odl-etl
    - target: /mitx
    - force_clone: True
    - require:
      - pkg: install_python_3

install_mitx_residential_etl_requirements:
  virtualenv.managed:
    - name: /mitx/mitx_etl
    - system_site_packages: False
    - requirements: /mitx/requirements.txt
    - env_vars:
        PATH_VAR: '/usr/local/bin/pip3'
    - require:
      - git: clone_mitx_etl_repo
      - pkg: install_python3_pip

{% for key, value in salt.pillar.get('edx:mitx_etl:mitx_residential_etl:settings', {}).items() %}
mitx_residential_etl_config:
  file.managed:
    - name: /mitx/settings.json
    - contents: |
        settings: {{ value|json(indent=2, sort_keys=True) |indent(8) }}
    - require:
      - git: clone_mitx_etl_repo
{% endfor %}

ensure_upload_bucket_exists:
  boto_s3_bucket.present:
    - Bucket: {{ settings.S3Bucket.bucket }}
    - Versioning:
        Status: Enabled
    - region: us-east-1

add_task_to_cron:
  cron.present:
    - name: 'source /mitx/mitx_etl/bin/activate && python3 /mitx/mitx_residential_etl.py'
    - comment: mitx_residential_etl_script
    - special: '@daily'
    - require:
      - file: mitx_residential_etl_config
      - boto_s3_buclet: ensure_upload_bucket_exists
