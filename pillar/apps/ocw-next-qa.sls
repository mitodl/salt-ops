
ocw-next:
  website_bucket: ocw-website-applications-qa
  source_data_bucket: open-learning-course-data-rc
  search_api_url: //discussions-rc.odl.mit.edu/api/v0/search/
  ocw_to_hugo_git_ref: release-candidate
  hugo_course_publisher_git_ref: release-candidate
  fastly_api_token: __vault__::secret-open-courseware/rc-apps/fastly-api-token>data>value
  fastly_service_id: __vault__::secret-open-courseware/rc-apps/fastly-service-id>data>value

node:
  version: 12.19.0
  pkg:
    version: 12
    use_upstream_repo: True
