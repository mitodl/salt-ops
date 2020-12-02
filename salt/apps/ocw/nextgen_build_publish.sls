{% set ocw_next = salt.pillar.get('ocw-next') %}

run_ocw_to_hugo:
  cmd.run:
    # Installing ocw-to-hugo without the `-g' switch leaves us without an
    # `ocw-to-hugo' executable, so we use the path to `index.js'
    - name: node src/bin/index.js -i /opt/ocw/open-learning-course-data -o /opt/ocw/hugo-course-publisher/site/ --strips3 --staticPrefix /coursemedia
    # `cwd' is specified because it drops a log file here.
    - cwd: /opt/ocw/ocw-to-hugo
    - runas: caddy

run_hugo_course_publisher:
  cmd.run:
    - name: npm run build
    # `cwd' is specified because it drops a log file here.
    - cwd: /opt/ocw/hugo-course-publisher
    - runas: caddy
    - require:
      - cmd: run_ocw_to_hugo

upload_to_web_bucket:
  # I don't think there's a Salt state module for `aws s3 sync'
  cmd.run:
    - name: aws s3 sync /opt/ocw/hugo-course-publisher/dist/ s3://{{ ocw_next.website_bucket }}/ --delete --only-show-errors
    - runas: caddy
    - require:
      - cmd: run_hugo_course_publisher

# TODO: Flush CDN cache via API
