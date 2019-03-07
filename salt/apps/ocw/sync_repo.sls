configure_ocw_src_git_sparsecheckout:
  git.config_set:
    - name: core.sparseCheckout
    - value: True
    - cwd: /usr/local/Plone/zeocluster/src

configure_ocw_publishing_git_sparsecheckout:
  git.config_set:
    - name: core.sparseCheckout
    - value: True
    - cwd: /usr/local/Plone/zeocluster/publishing

add_ocw_publishing_to_sparsecheckout:
  file.managed:
    - name: /usr/local/Plone/zeocluster/src/.git/info/sparse-checkout
    - contents: 'plone/src'

add_ocw_src_to_sparsecheckout:
  file.managed:
    - name: /mnt/ocwfileshare/OCWEngines/.git/info/sparse-checkout
    - contents: 'plone/publishing'

git_pull_ocw_src_folder:
  git.latest:
    - name: https://github.com/mitocw/ocwcms
    - target: /usr/local/Plone/zeocluster/src
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True

git_pull_ocw_engines_folder:
  git.latest:
    - name: https://github.com/mitocw/ocwcms
    - target: /mnt/ocwfileshare/OCWEngines
    - force_checkout: True
    - force_clone: True
    - force_reset: True
    - force_fetch: True
    - update_head: True
