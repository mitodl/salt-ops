{% set ocw_next = salt.pillar.get('ocw-next') %}

sync_open_learning_course_data:
  # I don't think there's a Salt state module for `aws s3 sync'
  cmd.run:
    - name: aws s3 sync s3://{{ ocw_next.source_data_bucket }}/ /home/ocw/open-learning-course-data/ --delete --only-show-errors
    - runas: ocw
