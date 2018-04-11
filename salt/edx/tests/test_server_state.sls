ensure_data_dir_symlink_has_proper_target:
  testinfra.file:
    - name: /edx/app/edxapp/data
    - is_symlink: True
    - linked_to:
        expected: {{ salt.pillar.get('edx:edxapp:GIT_REPO_DIR') }}
        comparison: eq
    - user:
        expected: edxapp
        comparison: eq
    - group:
        expected: www-data
        comparison: eq
