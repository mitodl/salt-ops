{% set libgit = salt.grains.filter_by({
    'default': {
        'tag': 'v0.24.0',
        'hash': 'sha256=1c6693f943bee3f634b9094376f93e7e03b9ca77354a33f4e903fdcb2ee8b2b0',
    },
    'Debian': {
        'pkgs': [
            'pkg-config',
            'cmake',
            'gcc',
            'make',
            'libssl-dev',
            'libssh2-1-dev'
        ]
    },
    'RedHat': {
        'pkgs': [
            'cmake',
            'gcc',
            'make',
            'openssl-devel',
            'libssh-devel'
        ]
    }
}, grain='os_family', merge=salt.pillar.get('salt_master:libgit'), base='default') %}

install_libgit_build_tools:
  pkg.installed:
    - pkgs: {{ libgit.pkgs }}

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
