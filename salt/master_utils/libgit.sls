{% set libgit = salt.grains.filter_by({
    'default': {
        'tag': 'v0.25.1',
        'hash': 'sha256=7ae8e699ff7ff9a1fa702249140ee31ea6fd556bf7968e84e38165870667bcb1',
    },
    'Debian': {
        'pkgs': [
            'pkg-config',
            'cmake',
            'gcc',
            'make',
            'libssl-dev',
            'libssh2-1-dev',
            'python-pip',
            'python-dev'
        ]
    },
    'RedHat': {
        'pkgs': [
            'cmake',
            'gcc',
            'make',
            'openssl-devel',
            'libssh-devel',
            'python-pip',
            'python-devel'
        ]
    }
}, grain='os_family', merge=salt.pillar.get('salt_master:libgit'), base='default') %}

install_libgit_build_tools:
  pkg.installed:
    - pkgs: {{ libgit.pkgs|tojson }}
    - reload_modules: True

download_libgit_source:
  archive.extracted:
    - name: /tmp/libgit2
    - source: https://github.com/libgit2/libgit2/archive/{{ libgit.tag }}.tar.gz
    - source_hash: {{ libgit.hash }}
    - archive_format: tar
    - tar_options: xv

compile_libgit:
  cmd.run:
    - cwd: /tmp/libgit2/libgit2-{{ libgit.tag.strip('v') }}
    - name: cmake . && make install && ldconfig
    - creates: /usr/local/lib/libgit2.so
    - require:
        - archive: download_libgit_source
        - pkg: install_libgit_build_tools

install_pygit:
  pip.installed:
    - name: pygit2
    - require:
        - cmd: compile_libgit
