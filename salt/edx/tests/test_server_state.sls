{% from "shared/edx/mitx.jinja" import edx with context %}

ensure_data_dir_symlink_has_proper_target:
  testinfra.file:
    - name: /edx/app/edxapp/data
    - is_symlink: True
    - linked_to:
        expected: {{ edx.edxapp_git_repo_dir }}
        comparison: eq
    - user:
        expected: edxapp
        comparison: eq
    - group:
        expected: www-data
        comparison: eq
