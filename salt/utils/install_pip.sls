{% set python_dependencies = salt.grains.filter_by({
    'default': {
      'python_libs': ['testinfra']
    },
    'Debian': {
      'pkgs': ['python-dev', 'python', 'curl'],
    },
    'RedHat': {
      'pkgs': ['python', 'python-devel', 'curl'],
    },
}, grain='os_family', merge=salt.pillar.get('python_dependencies'), base='default') %}

prepare_installation_of_pip_executable:
  pkg.installed:
    - pkgs: {{ python_dependencies.pkgs }}
    - reload_modules: True

install_global_pip_executable:
  cmd.run:
    - name: |
        curl -L "https://bootstrap.pypa.io/get-pip.py" > get_pip.py
        sudo python get_pip.py
        rm get_pip.py
    - reload_modules: True
    - unless: test -n `which pip`

install_python_libraries:
  pip.installed:
    - names: {{ python_dependencies.python_libs }}
    - require:
        - cmd: install_pip_executable
