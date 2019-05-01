{% set libgit = salt.grains.filter_by({
    'default': {
        'release': '0.27.3',
        'hash': 'sha256=50a57bd91f57aa310fb7d5e2a340b3779dc17e67b4e7e66111feac5c2432f1a550a57bd91f57aa310fb7d5e2a340b3779dc17e67b4e7e66111feac5c2432f1a5',
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
    - source: https://github.com/libgit2/libgit2/archive/v{{ libgit.release }}.tar.gz
    - source_hash: {{ libgit.hash }}
    - archive_format: tar
    - tar_options: xv

compile_libgit:
  cmd.run:
    - cwd: /tmp/libgit2/libgit2-{{ libgit.release }}
    - name: cmake . && make install && ldconfig
    - creates: /usr/local/lib/libgit2.so
    - require:
        - archive: download_libgit_source
        - pkg: install_libgit_build_tools

install_pygit:
  pip.installed:
    - name: pygit2=={{ libgit.release }}
    - require:
        - cmd: compile_libgit
