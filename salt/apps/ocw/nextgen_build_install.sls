{% set ocw_next = salt.pillar.get('ocw-next') %}

ensure_ocw_account_exists:
  user.present:
    - name: ocw
    - usergroup: True
    - home: /home/ocw
    - createhome: True
    - shell: /bin/bash
    - fullname: OCW applications user

ensure_os_package_prerequisites:
  pkg.installed:
    refresh: True
    pkgs:
      - aws
      - git
      # jq is not necessary, but it's nice to have for troubleshooting.
      - jq

ensure_nvm_installation:
  cmd.run:
    - name: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/{{ ocw_next.nvm_version }}/install.sh | bash
    - runas: ocw
    - cwd: /home/ocw
    - creates: /home/ocw/.nvm/nvm.sh
    # TODO: this does not update nvm if there's a newer release

ensure_node_version:
  cmd.script:
    - source: salt://apps/ocw/templates/nextgen_build_install_nvm.sh
    - cwd: /home/ocw
    - runas: ocw
    - template: jinja
    - context:
      - node_version: {{ ocw_next.node_version }}

git_pull_ocw_apps:
  git.latest:
    - name: https://github.com/mitodl/ocw-to-hugo.git
    - target: /home/ocw/ocw-to-hugo
    - rev: {{ ocw_next.ocw_to_hugo_git_ref }}
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True
    - user: ocw
  git.latest:
    - name: https://github.com/mitodl/hugo-course-publisher.git
    - target: /home/ocw/hugo-course-publisher
    - rev: {{ ocw_next.hugo_course_publisher_git_ref }}
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True
    - user: ocw

manage_course_publisher_env_file:
  file.managed:
    - name: /home/ocw/hugo-course-publisher/.env
    - user: ocw
    - group: ocw
    - mode: 0640
    - contents: |
        SEARCH_API_URL={{ ocw_next.search_api_url }}

install_ocw_apps:
  cmd.script:
    # not templatized yet, but it's in the templates directory in case we
    # want to later ...
    source: salt://apps/ocw/templates/nextgen_install_ocw_apps.sh
    runas: ocw
