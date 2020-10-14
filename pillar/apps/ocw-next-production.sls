
ocw-next:
  website_bucket: ocw-website-applications-production
  source_data_bucket: open-learning-course-data-production
  search_api_url: //open.mit.edu/api/v0/search/
  ocw_to_hugo_git_ref: release
  hugo_course_publisher_git_ref: release
  fastly_api_token: __vault__::secret-open-courseware/production-apps/fastly-api-token>data>value
  fastly_service_id: __vault__::secret-open-courseware/production-apps/fastly-service-id>data>value

node:
  version: 12.19.0
  pkg:
    version: 12
    use_upstream_repo: True
