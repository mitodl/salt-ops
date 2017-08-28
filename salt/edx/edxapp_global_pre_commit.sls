{# edX has a bug that results in course exports removing the run
   as part of the course data, so we need to run a pre-commit git
   hook during the export to add that data back to the course content #}
install_pre_commit_template_for_course_export:
  file.managed:
    - name: /usr/share/git-core/templates/hooks/pre-commit
    - source: salt://edx/files/edx_export_pre_commit.sh
    - mode: 0755
