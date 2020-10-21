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

ensure_state_of_caddy_home:
  # the formula doesn't create a caddy home dir, but we actually want it
  # because we need a place for dotfiles, etc., that are created by
  # npm.
  file.directory:
    - name: /home/caddy
    - user: caddy
    - group: caddy

ensure_state_of_opt_ocw:
  file.directory:
    - name: /opt/ocw
    - user: caddy
    - group: caddy
    - dir_mode: '0755'

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
      - git: git_pull_hugo_course_publisher

install_ocw_apps:
  cmd.script:
    # not templatized yet, but it's in the templates directory in case we
    # want to later ...
    - source: salt://apps/ocw/templates/nextgen_install_ocw_apps.sh
    - runas: caddy
    - require:
      - git: git_pull_hugo_course_publisher

install_caddy_webhook_script:
  file.managed:
    - name: /opt/ocw/webhook-publish.sh
    - user: caddy
    - group: caddy
    - mode: 0700
    - source: salt://apps/ocw/templates/webhook-publish.sh.jinja
    - template: jinja
    - context:
        website_bucket: {{ ocw_next.website_bucket }}
        source_data_bucket: {{ ocw_next.source_data_bucket }}
        fastly_api_token: {{ ocw_next.fastly_api_token }}
        fastly_service_id: {{ ocw_next.fastly_service_id }}
