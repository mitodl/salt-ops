bootstrap_gitfs_settings:
  file.managed:
    - name: /etc/salt/master.d/extfs.conf
    - contents: |
        fileserver_backend:
          - git
          - roots
        gitfs_provider: pygit2
        gitfs_remotes:
          - https://github.com/mitodl/master-formula
