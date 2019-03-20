{% set python_dependencies = salt.grains.filter_by({
    'default': {
      'python_libs': ['testinfra~=1.19', 'pyinotify'],
      'pkgs': ['gcc', 'make']
    },
    'Debian': {
      'pkgs': ['python-dev', 'python', 'curl', 'dnsutils'],
    },
    'RedHat': {
      'pkgs': ['python', 'python-devel', 'curl', 'bind-utils'],
    },
}, grain='os_family', merge=salt.pillar.get('python_dependencies'), base='default') %}

prepare_installation_of_pip_executable:
  pkg.installed:
    - pkgs: {{ python_dependencies.pkgs|tojson }}
    - reload_modules: True

install_global_pip_executable:
  cmd.run:
    - name: |
        curl -L "https://bootstrap.pypa.io/get-pip.py" > get_pip.py
        sudo python get_pip.py 'pip<18.1'
        rm get_pip.py
    - reload_modules: True
    - unless: which pip
    - reload_modules: True

install_python_libraries:
  pip.installed:
    - names: {{ python_dependencies.python_libs|tojson }}
    - reload_modules: True
