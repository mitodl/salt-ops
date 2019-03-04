configure_ocw_src_git_sparsecheckout:
  git.config_set:
    - name: core.sparsecheckout
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
    - contents: 'plone/publishing'

add_ocw_src_to_sparsecheckout:
  file.managed:
    - name: /mnt/ocwfileshare/OCWEngines/.git/info/sparse-checkout
    - contents: 'plone/src'

git_pull_ocw_src_folder:
  git.latest:
    - name: https://github.com/mitocw/ocwcms
    - target: /usr/local/Plone/zeocluster/src

git_pull_ocw_engines_folder:
  git.latest:
    - name: https://github.com/mitocw/ocwcms
    - target: /mnt/ocwfileshare/OCWEngines
