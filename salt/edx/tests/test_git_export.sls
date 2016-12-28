{% set git_export_dir = salt.pillar.get('edx:edxapp:GIT_REPO_EXPORT_DIR',
                                        '/edx/var/edxapp/export_course_repos') %}

test_git_export_dir_exists:
  testinfra.file:
    - name: {{ git_export_dir }}
    - exists: True
    - is_directory: True
    - user:
        expected: www-data
        comparison: eq
    - group:
        expected: edxapp
        comparison: eq

test_git_package_latest_version:
  testinfra.package:
    - name: git
    - is_installed: True
    - version:
        expected: '2.9'
        comparison: search
