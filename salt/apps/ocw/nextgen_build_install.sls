{% set ocw_next = salt.pillar.get('ocw-next') %}

ensure_ocw_account_exists:
  user.present:
    - name: ocw
    - usergroup: True
    - home: /home/ocw
    - createhome: True
    - shell: /bin/bash
    - fullname: OCW applications user

manage_yarn_pkg_repo:
  pkgrepo.managed:
    - name: deb https://dl.yarnpkg.com/debian/ stable main
    - key_url: https://dl.yarnpkg.com/debian/pubkey.gpg

ensure_os_package_prerequisites:
  pkg.installed:
    - refresh: True
    - pkgs:
        - aws
        - git
        - build-essential
        - gcc
        - g++
        - make
        - yarn
        - jq

git_pull_ocw_to_hugo:
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
    - require:
      - pkg: ensure_os_package_prerequisites

git_pull_hugo_course_publisher:
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
    - require:
      - pkg: ensure_os_package_prerequisites

manage_course_publisher_env_file:
  file.managed:
    - name: /home/ocw/hugo-course-publisher/.env
    - user: ocw
    - group: ocw
    - mode: 0640
    - contents: |
        SEARCH_API_URL={{ ocw_next.search_api_url }}
    - require:
      - git: git_pull_ocw_to_hugo
      - git: git_pull_hugo_course_publisher

install_ocw_apps:
  cmd.script:
    # not templatized yet, but it's in the templates directory in case we
    # want to later ...
    - source: salt://apps/ocw/templates/nextgen_install_ocw_apps.sh
    - runas: ocw
    - require:
      - git: git_pull_ocw_to_hugo
      - git: git_pull_hugo_course_publisher
