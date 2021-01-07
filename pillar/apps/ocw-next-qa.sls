
ocw-next:
  website_bucket: ocw-website-applications-qa
  source_data_bucket: open-learning-course-data-rc
  search_api_url: //discussions-rc.odl.mit.edu/api/v0/search/
  ocw_to_hugo_git_ref: release-candidate
  ocw_www_git_ref: main
  ocw_course_hugo_starter_git_ref: main
  fastly_api_token: __vault__::secret-open-courseware/rc-apps/fastly-api>data>token
  fastly_service_id: __vault__::secret-open-courseware/rc-apps/fastly-api>data>service_id
  course_base_url: https://ocwnext-rc.odl.mit.edu/courses

node:
  version: 12.19.0
  pkg:
    version: 12
    use_upstream_repo: True
