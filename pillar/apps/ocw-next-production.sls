
ocw-next:
  website_bucket: ocw-website-applications-production
  ocw_to_hugo_bucket: ocw-to-hugo-output-production
  source_data_bucket: open-learning-course-data-production
  search_api_url: //open.mit.edu/api/v0/search/
  ocw_www_git_ref: release
  ocw_course_hugo_starter_git_ref: release
  fastly_api_token: __vault__::secret-open-courseware/production-apps/fastly-api>data>token
  fastly_service_id: __vault__::secret-open-courseware/production-apps/fastly-api>data>service_id
  course_base_url: https://ocwnext.odl.mit.edu/courses
  ocw_studio_base_url: https://ocw-studio.odl.mit.edu/
  gtm_account_id: GTM-NMQZ25T
  mailchimp_audience_id: e07062bda1v
  mailchmip_user_id: ad81d725159c1f322a0c54837

node:
  version: 12.19.0
  pkg:
    version: 12
    use_upstream_repo: True
