
ocw-next:
  website_bucket: ocw-beta-production-course-site
  source_data_bucket: open-learning-course-data-production
  search_api_url: //open.mit.edu/api/v0/search/
  ocw_to_hugo_git_ref: master
  hugo_course_publisher_git_ref: master

node:
  version: 12.18.4
  install_from_ppa: True
  ppa:
    repository_url: https://deb.nodesource.com/node_12.x
