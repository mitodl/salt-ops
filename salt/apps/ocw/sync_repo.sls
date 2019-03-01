configure_ocw_src_git_sparsecheckout:
  git.config_set:
    - name: core.sparsecheckout
    - value: True
    - cwd: /usr/local/Plone/zeocluster/src

configure_ocw_publishing_git_sparsecheckout:
  git.config_set:
    - name: core.sparsecheckout
    - value: True
    - cwd: /usr/local/Plone/zeocluster/publishing

add_ocw_publishing_to_sparsecheckout:
  cmd.run:
    - cwd: /usr/local/Plone/zeocluster/src
    - name: echo plone/publishing >> .git/info/sparse-checkout

add_ocw_src_to_sparsecheckout:
  cmd.run:
    - cwd: /mnt/ocwfileshare/OCWEngines
    - name: echo plone/src >> .git/info/sparse-checkout

git_pull_ocw_src_folder:
  git.latest:
    - name: https://github.com/mitocw/ocwcms
    - target: /usr/local/Plone/zeocluster/src

git_pull_ocw_engines_folder:
  git.latest:
    - name: https://github.com/mitocw/ocwcms
    - target: /mnt/ocwfileshare/OCWEngines
