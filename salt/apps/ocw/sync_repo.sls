add_private_github_ssh_key:
  file.managed:
    - name: /root/.ssh/ocw_ssh_key
    - contents_pillar: ocw:github_ssh_key
    - mode: 0600
    - makedirs: True

configure_ocw_src_git_sparsecheckout:
  module.run:
    - name: git.config_set
    - key: core.sparseCheckout
    - value: True
    - cwd: /usr/local/Plone/zeocluster/src

configure_ocw_publishing_git_sparsecheckout:
  module.run:
    - name: git.config_set
    - key: core.sparseCheckout
    - value: True
    - cwd: /usr/local/Plone/zeocluster/publishing

add_ocw_publishing_to_sparsecheckout:
  file.managed:
    - name: /usr/local/Plone/zeocluster/src/.git/info/sparse-checkout
    - contents: 'plone/src'

{% if salt['file.directory_exists']('/mnt/ocwfileshare/OCWEngines') %}
add_ocw_src_to_sparsecheckout:
  file.managed:
    - name: /mnt/ocwfileshare/OCWEngines/.git/info/sparse-checkout
    - contents: 'plone/publishing'

git_pull_ocw_engines_folder:
  git.latest:
    - name: git@github.com:mitocw/ocwcms
    - target: /mnt/ocwfileshare/OCWEngines
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True
    - user: root
    - identity: /root/.ssh/ocw_ssh_key
{% endif %}

git_pull_ocw_src_folder:
  git.latest:
    - name: git@github.com:mitocw/ocwcms
    - target: /usr/local/Plone/zeocluster/src
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True
    - user: root
    - identity: /root/.ssh/ocw_ssh_key
