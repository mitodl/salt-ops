
ocw-next:
  website_bucket: ocw-website-applications-qa
  ocw_to_hugo_bucket: ocw-to-hugo-output-qa
  source_data_bucket: open-learning-course-data-rc
  search_api_url: //discussions-rc.odl.mit.edu/api/v0/search/
  ocw_www_git_ref: release-candidate
  ocw_hugo_themes_git_ref: release-candidate
  fastly_api_token: __vault__::secret-open-courseware/rc-apps/fastly-api>data>token
  fastly_service_id: __vault__::secret-open-courseware/rc-apps/fastly-api>data>service_id
  course_base_url: https://ocwnext-rc.odl.mit.edu/courses
  ocw_studio_base_url: https://ocw-studio-rc.odl.mit.edu/
  gtm_account_id: GTM-PJMJGF6

node:
  version: 12.19.0
  pkg:
    version: 12
    use_upstream_repo: True
