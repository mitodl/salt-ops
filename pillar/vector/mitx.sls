vector:
  configuration:

    api:
      enabled: true

    log_schema:
      timestamp_key: "@timestamp"
      host_key: log_host

    sources:

      {% if 'edx' in salt.grains.get('roles') %}

      nginx_access_log:
        type: file
        file_key: log_file
        include:
          - /edx/var/log/nginx/access.log

      nginx_error_log:
        type: file
        file_key: log_file
        include:
          - /edx/var/log/nginx/error.log

      # This is gone. Changed in Koa?
      # cms_log:
      #   type: file
      #   include:
      #     - /edx/var/log/cms/edx.log

      cms_stderr_log:
        type: file
        file_key: log_file
        include:
          - /edx/var/log/supervisor/cms-stderr.log
        multiline:
          start_pattern: '^\[?\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
          mode: halt_before
          condition_pattern: '^\[?\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
          timeout_ms: 500

      # This is gone. Changed in Koa?
      # lms_log:
      #   type: file
      #   include:
      #     - /edx/var/log/lms/edx.log

      lms_stderr_log:
        type: file
        file_key: log_file
        include:
          - /edx/var/log/supervisor/lms-stderr.log
        multiline:
          start_pattern: '^\[?\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
          mode: halt_before
          condition_pattern: '^\[?\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
          timeout_ms: 500

      gitreload_log:
        type: file
        file_key: log_file
        include:
          - /edx/var/log/gr/gitreload.log

      xqueue_stderr_log:
        type: file
        file_key: log_file
        include:
          - /edx/var/log/supervisor/xqueue-stderr.log
        multiline:
          start_pattern: '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
          mode: halt_before
          condition_pattern: '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
          timeout_ms: 500

      {% endif %}

      {% if 'edx-worker' in salt.grains.get('roles') %}

      worker_cms_stderr_log:
        type: file
        file_key: log_file
        include:
          - /edx/var/log/supervisor/cms_*stderr.log
        multiline:
          start_pattern: '^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
          mode: halt_before
          condition_pattern: '^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
          timeout_ms: 500

      worker_lms_stderr_log:
        type: file
        file_key: log_file
        include:
          - /edx/var/log/supervisor/lms_*stderr.log
        multiline:
          start_pattern: '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
          mode: halt_before
          condition_pattern: '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
          timeout_ms: 500

      {% endif %}

      tracking_log:
        file_key: log_file
        type: file
        include:
          - /edx/var/log/tracking/tracking.log

      auth_log:
        type: file
        file_key: log_file
        include:
          - /var/log/auth.log

    transforms:

      {% if 'edx' in salt.grains.get('roles') %}

      nginx_access_log_parser:
        inputs:
          - nginx_access_log
        type: logfmt_parser
        types:
          time: timestamp|%F %T%:z
          client: bytes
          status: bytes
          upstream_addr: bytes
          upstream_status: bytes
        field: message
        drop_field: true

      nginx_access_log_sampler:
        inputs:
          - nginx_access_log_parser
        type: filter
        condition:
          type: check_fields
          "message.not_contains": "ELB-HealthChecker"

      nginx_access_log_field_adder:
        inputs:
          - nginx_access_log_sampler
        type: add_fields
        fields:
          labels:
            - nginx_access
            - edx_nginx_access
          environment: {{ salt.grains.get('environment') }}

      nginx_access_log_timestamp_renamer:
        inputs:
          - nginx_access_log_field_adder
        type: rename_fields
        fields:
          time: "@timestamp"

      nginx_error_log_parser:
        inputs:
          - nginx_error_log
        type: regex_parser
        drop_failed: true
        field: message
        overwrite_target: true
        patterns:
          - '^(?P<time>\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) \[(?P<log_level>\w+)\] \S+ (?P<message>.*)$'
        types:
          time: timestamp|%Y/%m/%d %T

      nginx_error_log_field_adder:
        inputs:
          - nginx_error_log_parser
        type: add_fields
        fields:
          labels:
            - nginx_error
            - edx_nginx_error
          environment: {{ salt.grains.get('environment') }}

      nginx_error_log_timestamp_renamer:
        inputs:
          - nginx_error_log_field_adder
        type: rename_fields
        fields:
          time: "@timestamp"

      # the following transform has to parse lines with varying formats.
      # examples:
      # 1)
      # [2021-01-27 19:03:16 +0000] [894] [INFO] Listening at: http://127.0.0.1:8010 (894)
      #
      # 2)
      # 2021-01-28 18:52:48,256 ERROR 52258 [edx_proctoring.api] [user 8] [ip 208.127.88.219] api.py:341 - Cannot find the proctored exam in this course course-v1:MITx+mkd.2021_1+2021_Spring with content_id: block-v1:MITx+mkd.2021_1+2021_Spring+type@sequential+block@7a1ecea654fb49699dde8a40a3a72e3d
      # NoneType: None
      #
      cms_stderr_log_parser:
        inputs:
          - cms_stderr_log
        type: regex_parser
        drop_failed: true
        field: message
        overwrite_target: true
        patterns:
          - '(?ms)^\[(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) [+\-]\d{4}\] \[(?P<pid>\d+)\] \[(?P<log_level>[A-Z]+)\] (?P<message>.*)'
          - '(?ms)^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}),\d{3} (?P<log_level>[A-Z]+) (?P<pid>\d+) (?P<message>.*)'
        types:
          time: timestamp|%F %T
          pid: bytes

      cms_stderr_sampler:
        inputs:
          - cms_stderr_log_parser
        type: filter
        condition:
          type: check_fields
          "message.not_regex": "^(GET|POST)"

      cms_stderr_log_field_adder:
        inputs:
          - cms_stderr_sampler
        type: add_fields
        fields:
          labels:
            - edx_cms_stderr
          environment: {{ salt.grains.get('environment') }}

      cms_stderr_timestamp_renamer:
        inputs:
          - cms_stderr_log_field_adder
        type: rename_fields
        fields:
          time: "@timestamp"

      # the following transform also has to process lines with varying formats.
      # examples:
      # 1)
      #     [2021-02-25 19:09:22 +0000] [2056637] [INFO] POST /search/course_discovery/
      # 2)
      #     2021-02-25 19:09:22,728 WARNING 2056637 [django.security.csrf] [user None] [ip 127.0.0.1] log.py:222 - Forbidden (CSRF cookie not set.): /search/course_discovery/
      lms_stderr_log_parser:
        inputs:
          - lms_stderr_log
        type: regex_parser
        drop_failed: true
        field: message
        overwrite_target: true
        patterns:
          - '(?ms)^\[(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) [+\-]\d{4}\] \[(?P<pid>\d+)\] \[(?P<log_level>[A-Z]+)\] (?P<message>.*)'
          - '(?ms)^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}),\d{3} (?P<log_level>\S+) (?P<pid>\d+) \[(?P<namespace>.*?)\] \[user (?P<user>.*?)\] \[ip (?P<client_ip>.*?)\] (?P<file>.*?):(?P<line_number>\d+) - (?P<message>.*)'
        types:
          time: timestamp|%F %T
          pid: bytes
          line_number: bytes

      lms_stderr_sampler:
        inputs:
          - lms_stderr_log_parser
        type: filter
        condition:
          type: check_fields
          "message.not_regex": "^(GET|POST)"

      lms_stderr_log_field_adder:
        inputs:
          - lms_stderr_sampler
        type: add_fields
        fields:
          labels:
            - edx_lms_stderr
          environment: {{ salt.grains.get('environment') }}

      lms_stderr_timestamp_renamer:
        inputs:
          - lms_stderr_log_field_adder
        type: rename_fields
        fields:
          time: "@timestamp"

      # gitreload log sample:
      # 2021-02-28 19:54:48,495 DEBUG 2894216 [gitreload] web.py:64 - ip-10-7-3-149- Received push event from github
      #
      gitreload_parser:
        inputs:
          - gitreload_log
        type: regex_parser
        drop_failed: true
        field: message
        overwrite_target: true
        patterns:
          - '(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}),\d{3} (?P<log_level>[A-Z]+) (?P<pid>\d+) \[.*?\] (?P<filename>.+?):(?P<line_number>\d+) - (?P<host>.+?)- (?P<message>.*)'
        types:
          time: timestamp|%F %T
          pid: bytes
          line_number: bytes

      gitreload_log_field_adder:
        inputs:
          - gitreload_parser
        type: add_fields
        fields:
          labels:
            - edx_gitreload
          environment: {{ salt.grains.get('environment') }}

      gitreload_timestamp_renamer:
        inputs:
          - gitreload_log_field_adder
        type: rename_fields
        fields:
          time: "@timestamp"

      xqueue_stderr_log_parser:
        inputs:
          - xqueue_stderr_log
        type: regex_parser
        drop_failed: true
        field: message
        overwrite_target: true
        patterns:
          - '(?ms)^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[(?P<pid>.*?)\] \[(?P<log_level>).*?\] (?P<message>.*)'
        types:
          time: timestamp|%F %T
          pid: bytes

      xqueue_stderr_log_sampler:
        inputs:
          - xqueue_stderr_log_parser
        type: filter
        condition:
          type: check_fields
          "message.not_regex": '^(GET|POST)'

      xqueue_stderr_log_field_adder:
        inputs:
          - xqueue_stderr_log_sampler
        type: add_fields
        fields:
          labels:
            - edx_xqueue
          environment: {{ salt.grains.get('environment') }}

      xqueue_stderr_timestamp_renamer:
        inputs:
          - xqueue_stderr_log_field_adder
        type: rename_fields
        fields:
          time: "@timestamp"

      {% endif %}

      {% if 'edx-worker' in salt.grains.get('roles') %}

      # edX worker's "cms" supervisor stderr log,
      # e.g. /edx/var/log/supervisor/cms_default_4-stderr.log
      # is formatted as in these examples:
      #
      # [2021-02-25 16:29:59,191: ERROR/ForkPoolWorker-4] git_auto_export.tasks.async_export_to_git[b6320d3b-d208-4ea4-ae53-4d0fbedc247c]: Failed async course content export to git (course id: course-v1:MITx+8.011r_8+2021_Spring): Unable to push changes.  This is usually because the remote repository cannot be contacted
      # [2021-02-25 18:05:02,524: INFO/MainProcess] Received task: lms.djangoapps.discussion.tasks.update_discussions_map[9413651f-6863-4f62-bc61-85f565515568]  ETA:[2021-02-25 18:05:32.505810+00:00]
      # [2021-02-25 16:31:14,432: ERROR/ForkPoolWorker-4] Error running git push command: b"To github.mit.edu:MITx-Studio2LMS/content-mit-8011r_8-2021_Spring.git\n ! [rejected]  [...]
      #
      worker_cms_stderr_log_parser:
        inputs:
          - worker_cms_stderr_log
        type: regex_parser
        drop_failed: true
        field: message
        overwrite_target: true
        patterns:
          - '(?ms)^\[(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}): (?P<log_level>[A-Z]+)/(?P<process>.*?)\] (?P<message>.*)'
        types:
          time: timestamp|%F %T,%3f

      # edX worker's "lms" supervisor stderr log,
      # e.g. /edx/var/log/supervisor/lms_default_4-stderr.log
      # is formatted as in this example:
      #
      # 2021-02-25 19:45:01,275 WARNING 1403559 [edx_toggles.toggles.internal.waffle] [user None] [ip None] waffle.py:207 - Grades: Flag 'grades.enforce_freeze_grade_after_course_end' accessed without a request
      #
      worker_lms_stderr_log_parser:
        inputs:
          - worker_lms_stderr_log
        type: regex_parser
        drop_failed: true
        field: message
        overwrite_target: true
        patterns:
          - '(?ms)^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}) (?P<log_level>[A-Z]+) (?P<pid>\d+) \[(?P<namespace>.*?)\] \[user (?P<user>.*?)\] \[ip (?P<client_ip>.*?)\] (?P<filename>.+?):(?P<line_number>\d+) - (?P<message>.*)'
        types:
          time: timestamp|%F %T,%3f
          pid: bytes
          line_number: bytes

      worker_stderr_log_field_adder:
        inputs:
          - worker_cms_stderr_log_parser
          - worker_lms_stderr_log_parser
        type: add_fields
        fields:
          labels:
            - edx_worker
          environment: {{ salt.grains.get('environment') }}

      worker_stderr_timestamp_renamer:
        inputs:
          - worker_stderr_log_field_adder
        type: rename_fields
        fields:
          time: "@timestamp"

      {% endif %}

      tracking_log_parser:
        inputs:
          - tracking_log
        type: json_parser
        field: message
        drop_field: true

      tracking_log_timestamp_coercer:
        inputs:
          - tracking_log_parser
        type: coercer
        types:
          time: timestamp|%FT%T%.6f%:z

      tracking_log_timestamp_renamer:
        inputs:
          - tracking_log_timestamp_coercer
        type: rename_fields
        fields:
          time: "@timestamp"

      tracking_log_field_adder:
        inputs:
          - tracking_log_timestamp_renamer
        type: add_fields
        fields:
          labels:
            - edx_tracking
          environment: {{ salt.grains.get('environment') }}

      auth_log_parser:
        inputs:
          - auth_log
        type: regex_parser
        drop_failed: true
        field: message
        overwrite_target: true
        patterns:
          - '^(?P<time>\w{3}\s+\d+\s+\d{2}:\d{2}:\d{2}) \S+ (?P<process>.*?): (?P<message>.*)'
        types:
          time: timestamp|%b %e %T

      auth_log_sampler:
        inputs:
          - auth_log_parser
        type: filter
        condition:
          type: check_fields
          "process.not_contains": "CRON"

      auth_log_field_adder:
        inputs:
          - auth_log_sampler
        type: add_fields
        fields:
          labels:
            - authlog
            - edx_authlog
          environment: {{ salt.grains.get('environment') }}

    sinks:

      {% if 'edx' in salt.grains.get('roles') %}

      elasticsearch_nginx_access:
        inputs:
          - nginx_access_log_timestamp_renamer
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-mitx-nginx-access-%Y.%W
        healthcheck: false

      elasticsearch_nginx_error:
        inputs:
          - nginx_error_log_timestamp_renamer
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-mitx-nginx-error-%Y.%W
        healthcheck: false

      elasticsearch_gitreload:
        inputs:
          - gitreload_timestamp_renamer
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-mitx-gitreload-%Y.%W
        healthcheck: false

      {% endif %}

      elasticsearch_lms_cms_worker:
        inputs:
          {% if 'edx' in salt.grains.get('roles') %}
          - cms_stderr_timestamp_renamer
          - lms_stderr_timestamp_renamer
          - xqueue_stderr_timestamp_renamer
          {% endif %}
          {% if 'edx-worker' in salt.grains.get('roles') %}
          - worker_stderr_timestamp_renamer
          {% endif %}
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-mitx-stderr-%Y.%W
        healthcheck: false

      elasticsearch_tracking:
        inputs:
          - tracking_log_field_adder
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-mitx-tracking-%Y.%W
        healthcheck: false

      elasticsearch_authlog:
        inputs:
          - auth_log_field_adder
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-authlog-%Y.%W
