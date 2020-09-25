{% set ocw_next = salt.pillar.get('ocw-next') %}

run_ocw_to_hugo:
  cmd.run:
    - name: node src/bin/index.js -i /home/ocw/open-learning-course-data -o /home/ocw/hugo-course-publisher/site/content --strips3 --staticPrefix /coursemedia
    - cwd: /home/ocw/ocw-to-hugo
    - runas: ocw

run_hugo_course_publisher:
  cmd.run:
    - name: npm run build
    - cwd: /home/ocw/hugo-course-publisher
    - runas: ocw
    - env:
      - NODE_OPTIONS: '-max_old_space_size=8192'
    - require:
      - cmd: run_ocw_to_hugo

upload_to_web_bucket:
  # I don't think there's a Salt state module for `aws s3 sync'
  cmd.run:
    - name: aws s3 sync /home/ocw/hugo-course-publisher/dist/ s3://{{ ocw_next.website_bucket }}/ --delete --only-show-errors
    - runas: ocw
    - require:
      - cmd: run_hugo_course_publisher

# TODO: Flush CDN cache via API
