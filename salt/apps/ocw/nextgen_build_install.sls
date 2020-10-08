{% set ocw_next = salt.pillar.get('ocw-next') %}

manage_yarn_pkg_repo:
  pkgrepo.managed:
    - name: deb https://dl.yarnpkg.com/debian/ stable main
    - key_url: https://dl.yarnpkg.com/debian/pubkey.gpg

ensure_os_package_prerequisites:
  pkg.installed:
    - refresh: True
    - pkgs:
        - awscli
        - git
        - build-essential
        - gcc
        - g++
        - make
        - yarn
        - jq

ensure_state_of_opt_ocw:
  file.directory:
    - name: /opt/ocw
    - user: caddy
    - group: caddy
    - dir_mode: '0755'

git_pull_ocw_to_hugo:
  git.latest:
    - name: https://github.com/mitodl/ocw-to-hugo.git
    - target: /opt/ocw/ocw-to-hugo
    - rev: {{ ocw_next.ocw_to_hugo_git_ref }}
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True
    - user: caddy
    - require:
      - pkg: ensure_os_package_prerequisites

git_pull_hugo_course_publisher:
  git.latest:
    - name: https://github.com/mitodl/hugo-course-publisher.git
    - target: /opt/ocw/hugo-course-publisher
    - rev: {{ ocw_next.hugo_course_publisher_git_ref }}
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True
    - user: caddy
    - require:
      - pkg: ensure_os_package_prerequisites

manage_course_publisher_env_file:
  file.managed:
    - name: /opt/ocw/hugo-course-publisher/.env
    - user: caddy
    - group: caddy
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
    - runas: caddy
    - require:
      - git: git_pull_ocw_to_hugo
      - git: git_pull_hugo_course_publisher

install_caddy_webhook_script:
  file.managed:
    - name: /usr/local/bin/webhook-publish.sh
    - user: caddy
    - group: caddy
    - mode: 0777
    - source: salt://apps/ocw/templates/webhook-publish.sh.jinja
    - template: jinja
    - context:
        website_bucket: {{ ocw_next.website_bucket }}
        source_data_bucket: {{ ocw_next.source_data_bucket }}