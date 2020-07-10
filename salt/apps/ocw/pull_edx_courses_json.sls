
pull_edx_courses_json:
  module.run:
    - name: s3.get
    - bucket: open-learning-course-data-production
    - path: edx_courses.json
    - local_file: /var/www/ocw/courses/edx_courses.json

ensure_ownership_and_perms_of_edx_courses_json:
  file.managed:
    - name: /var/www/ocw/courses/edx_courses.json
    - user: fsuser
    - group: fsuser
    - mode: 0644
