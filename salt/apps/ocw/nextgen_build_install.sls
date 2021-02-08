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
        - golang

ensure_state_of_hugo_binary:
  pkg.installed:
    - refresh: True
    - sources:
      - hugo: https://github.com/gohugoio/hugo/releases/download/v0.80.0/hugo_0.80.0_Linux-64bit.deb

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

ensure_state_of_log_directory:
  file.directory:
    - name: /opt/ocw/logs
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

git_pull_ocw_www:
  git.latest:
    - name: https://github.com/mitodl/ocw-www.git
    - target: /opt/ocw/ocw-www
    - rev: {{ ocw_next.ocw_www_git_ref }}
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True
    - user: caddy
    - require:
      - pkg: ensure_os_package_prerequisites

git_pull_ocw_course_hugo_starter:
  git.latest:
    - name: https://github.com/mitodl/ocw-course-hugo-starter.git
    - target: /opt/ocw/ocw-course-hugo-starter
    - rev: {{ ocw_next.ocw_course_hugo_starter_git_ref }}
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True
    - user: caddy
    - require:
      - pkg: ensure_os_package_prerequisites

manage_ocw_www_env_file:
  file.managed:
    - name: /opt/ocw/ocw-www/.env
    - user: caddy
    - group: caddy
    - mode: 0640
    - contents: |
        SEARCH_API_URL={{ ocw_next.search_api_url }}
    - require:
      - git: git_pull_ocw_www

manage_ocw_course_hugo_starter_env_file:
  file.managed:
    - name: /opt/ocw/ocw-course-hugo-starter/.env
    - user: caddy
    - group: caddy
    - mode: 0640
    - contents: |
        SEARCH_API_URL={{ ocw_next.search_api_url }}
    - require:
      - git: git_pull_ocw_course_hugo_starter

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
        ocw_to_hugo_bucket: {{ ocw_next.ocw_to_hugo_bucket }}
        source_data_bucket: {{ ocw_next.source_data_bucket }}
        fastly_api_token: {{ ocw_next.fastly_api_token }}
        fastly_service_id: {{ ocw_next.fastly_service_id }}
        ocw_to_hugo_git_ref: {{ ocw_next.ocw_to_hugo_git_ref }}
        ocw_www_git_ref: {{ ocw_next.ocw_www_git_ref }}
        ocw_course_hugo_starter_git_ref: {{ ocw_next.ocw_course_hugo_starter_git_ref }}
        course_base_url: {{ ocw_next.course_base_url }}
        ocw_studio_base_url: {{ ocw_next.ocw_studio_base_url }}
        gtm_account_id: {{ gtm_account_id }}