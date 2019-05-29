{% set engines_basedir = salt.pillar.get('ocw:engines_basedir', '/mnt/ocwfileshare/OCWEngines') %}

{% if 'engine' in salt.grains.get('ocw-cms-role', []) %}

{% set cron_log_dir = '/var/log/engines-cron' %}

# This would be nice, but takes hours to run ...
# ensure_ownership_of_engines_base_directory:
#   file.directory:
#     - name: {{ engines_basedir }}
#     - user: ocwuser
#     - group: ocwuser
#     - recurse:
#         - user
#         - group

ensure_state_of_cron_log_directory:
  file.directory:
    - name: {{ cron_log_dir }}
    - user: ocwuser
    - group: ocwuser
    - dir_mode: '0755'

ensure_state_of_engine_log_directory:
  file.directory:
    - name: "{{ engines_basedir }}/logs"
    - user: ocwuser
    - group: ocwuser
    - dir_mode: '0755'

manage_engines_conf:
  file.managed:
    - name: {{ engines_basedir }}/engines.conf
    - template: jinja
    - source: salt://apps/ocw/templates/engines.conf.jinja
    - user: ocwuser
    - group: ocwuser
    - mode: '0640'

generate_ocw_news_feeds_cronjob:
  cron.present:
    - identifier: generate_ocw_news_feeds
    - name: {{ engines_basedir }}/generate_ocw_news_feeds.sh > {{ cron_log_dir }}/generate_ocw_news_feeds.log 2>&1
    - user: ocwuser
    - minute: 0

youtube_csv_file_cronjob:
  cron.present:
    - identifier: generate_youtube_videos_csv
    - name: {{ engines_basedir }}/generate_youtube_videos_tab.sh > {{ cron_log_dir }}/generate_youtube_videos_tab.log 2>&1
    - user: ocwuser
    - minute: 1
    - hour: 6

# run_aka_scripts.sh executes the script that generates sitemap.xml
# and the script that generates a list of Zip URLs. See the `ocwcms' project.
# It depends on a file that's generated by runGenerateURLforSitemap.sh.
#
run_generate_url_for_sitemap_cronjob:
  cron.present:
    - identifier: run_generate_url_for_sitemap
    - name: {{ engines_basedir }}/runGenerateURLforSitemap.sh > {{ cron_log_dir }}/run_generate_url_for_sitemap.log 2>&1
    - user: ocwuser
    - minute: 4
    - hour: 4

run_aka_scripts_cronjob:
  cron.present:
    - identifier: run_aka_scripts
    - name: {{ engines_basedir }}/run_aka_scripts.sh {{ salt.pillar.get('ocw:engines_conf:production_host') }} > {{ cron_log_dir }}/run_aka_scripts.log  2>&1
    - user: ocwuser
    - minute: 4
    - hour: 5

transfer_edx_map_cronjob:
  cron.present:
    - identifier: transfer_edx_map_json
    - name: {{ engines_basedir }}/transfer_edxmap_json.sh > {{ cron_log_dir }}/transfer_edxmap_json.log 2>&1
    - user: root
    - minute: '*/5'

daily_broken_links_update_cronjob:
  cron.present:
    - identifier: run_broken_links_updater
    - name: {{ engines_basedir }}/run_broken_links_updater.sh > {{ cron_log_dir }}/run_broken_links_updater.log 2>&1
    - user: ocwuser
    - minute: 7
    - hour: 4

# Copy mitx_archived_courses.xml from CMS just before running generate_mitx_feeds.sh
copy_mitx_archived_courses_cronjob:
  cron.present:
    - identifier: copy_mitx_archived_courses
    - name: {{ engines_basedir }}/copy_mitx_archived_courses_xml_from_CMS.sh > {{ cron_log_dir }}/copy_mitx_archived_courses_xml_from_CMS.log 2>&1
    - user: root
    - minute: 30
    - hour: 4

mitx_feeds_cronjob:
  cron.present:
    - identifier: generate_mitx_feeds
    - name: {{ engines_basedir }}/generate_mitx_feeds.sh > {{ cron_log_dir }}/generate_mitx_feeds.log 2>&1
    - user: ocwuser
    - minute: 40
    - hour: 4

check_cache_size_cronjob:
  cron.present:
    - identifier: check_cache_size
    - name: {{ engines_basedir }}/check_cache_size.sh > {{ cron_log_dir }}/check_cache_size.log 2>&1
    - user: root
    - minute: 50
    - hour: 8

{% endif %}
