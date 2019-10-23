{% set python_dependencies = salt.grains.filter_by({
    'default': {
      'python_libs': ['testinfra', 'pyinotify'],
      'pkgs': ['gcc', 'make']
    },
    'Debian': {
      'pkgs': ['python3-dev', 'python3', 'curl', 'dnsutils'],
    },
    'RedHat': {
      'pkgs': ['python3', 'python3-devel', 'curl', 'bind-utils'],
    },
}, grain='os_family', merge=salt.pillar.get('python_dependencies'), default='Debian', base='default') %}

prepare_installation_of_pip_executable:
  pkg.installed:
    - pkgs: {{ python_dependencies.pkgs|tojson }}
    - reload_modules: True

install_global_pip_executable:
  cmd.run:
    - name: |
        curl -L "https://bootstrap.pypa.io/get-pip.py" > get_pip.py
        {{ salt.grains.get('pythonexecutable') }} get_pip.py
        rm get_pip.py
    - reload_modules: True
    - unless: {{ salt.grains.get('pythonexecutable') }} -m pip --version
    - reload_modules: True

install_python_libraries:
  pip.installed:
    - names: {{ python_dependencies.python_libs|tojson }}
    - reload_modules: True
