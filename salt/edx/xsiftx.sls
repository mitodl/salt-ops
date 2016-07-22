{% set repo = salt.pillar.get('edx:xsiftx:repo',
                              'https://github.com/mitodl/xsiftx') -%}
{% set version = salt.pillar.get('edx:xsiftx:version',
                              'aaa70e170e38e54c5d27a7a926dfd49fd8155fd6') -%}
{% set extra_sifter_repo = salt.pillar.get('edx:xsiftx:extra_sifter_repo',
                              'https://github.com/mitodl/sifters') -%}
{% set extra_sifter_dir = salt.pillar.get('edx:xsiftx:extra_sifter_dir',
                              '/usr/local/share/xsiftx/sifters') -%}
{% set cron_jobs = salt.pillar.get('edx:xsiftx:cron_jobs', []) -%}


install_xsiftx:
  pip.installed:
    - name: git+https://{{ repo }}@{{ version }}#egg=xsiftx
    - exists_action: w

{% if extra_sifter_repo is not None %}
install_extra_sifters
  git.latest:
    - name: {{ extra_sifter_repo }}
    - target: {{ extra_sifter_dir }}
{% endif %}
