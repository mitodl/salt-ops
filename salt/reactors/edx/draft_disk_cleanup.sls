remove_exported_courses_from_disk:
  local.cmd.run:
    - tgt: {{ data['id'] }}
    - arg:
        - rm -rf /edx/var/edxapp/export_course_repos/*
