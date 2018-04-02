install_python_requirements_for_all_datasources:
  pip.installed:
    - requirements: /opt/{{ salt.pillar.get('django:app_name') }}/requirements_all_ds.txt
    - bin_env: {{ salt.pillar.get('django:pip_path') }}
    - require:
        - pip: install_python_requirements
