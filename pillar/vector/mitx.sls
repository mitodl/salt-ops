{% set environment = salt.grains.get('environment') %}

{% if environment == 'mitx-qa' %}
{% set tracking_bucket = 'odl-residential-tracking-data-qa' %}
{% elif environment == 'mitx-production' %}
{% set tracking_bucket = 'odl-residential-tracking-data' %}
{% endif %}

vector:
  configuration:

    api:
      enabled: true

    log_schema:
      timestamp_key: vector_timestamp
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
        type: remap
        source: |
          parsed, err = parse_logfmt(.message)
          if parsed != null {
            .@timestamp = parse_timestamp!(parsed.time, "%F %T%:z")
            del(.message)
            ., err = merge(., parsed)
            .labels = ["nginx_access", "edx_nginx_access"]
            .environment = "{{ environment }}"
          } else {
            log(err, level: "error")
            .malformed = true
          }

      nginx_access_log_malformed_message_filter:
        inputs:
          - nginx_access_log_parser
        type: filter
        condition: .malformed != true

      nginx_access_log_healthcheck_filter:
        inputs:
          - nginx_access_log_malformed_message_filter
        type: filter
        condition: '! contains!(.message, "ELB-HealthChecker")'

      nginx_error_log_parser:
        inputs:
          - nginx_error_log
        type: remap
        source: |
          matches, err = parse_regex(
            .message,
            r'^(?P<time>\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) \[(?P<log_level>\w+)\] \S+ (?P<message>.*)$'
          )
          if matches != null {
            .message = matches.message
            .@timestamp = parse_timestamp!(matches.time, "%Y/%m/%d %T")
            .time = .@timestamp
            .labels = ["nginx_error", "edx_nginx_error"]
            .environment = "{{ environment }}"
          } else {
            log(err, level: "error")
            .malformed = true
          }

      nginx_error_log_malformed_message_filter:
        inputs:
          - nginx_error_log_parser
        type: filter
        condition: .malformed != true

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
        type: remap
        source: |
          match, err = parse_regex(
            .message,
            r'(?ms)^\[(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+\-]\d{4})\] \[(?P<pid>\d+)\] \[(?P<log_level>[A-Z]+)\] (?P<message>.*)'
          )
          if match != null {
            .@timestamp = parse_timestamp!(match.time, "%F %T %z")
          } else {
            match, err = parse_regex(
              .message,
              r'(?ms)^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}) (?P<log_level>[A-Z]+) (?P<pid>\d+) (?P<message>.*)'
            )
            if match != null {
              .@timestamp = parse_timestamp!(match.time, "%F %T,%3f")
            }
          }
          if err == null {
            .time = .@timestamp
            .message = match.message
            .log_level = match.log_level
            .pid = match.pid
            .labels = ["edx_cms_stderr"]
            .environment = "{{ environment }}"
          } else {
            log(err, level: "error")
            .malformed = true
          }

      cms_stderr_malformed_message_filter:
        inputs:
          - cms_stderr_log_parser
        type: filter
        condition: .malformed != true

      cms_stderr_httpreq_filter:
        inputs:
          - cms_stderr_malformed_message_filter
        type: filter
        condition: "! match!(.message, r'^(GET|POST|HEAD|PUT)')"

      # the following transform also has to process lines with varying formats.
      # examples:
      # 1)
      #     [2021-02-25 19:09:22 +0000] [2056637] [INFO] POST /search/course_discovery/
      # 2)
      #     2021-02-25 19:09:22,728 WARNING 2056637 [django.security.csrf] [user None] [ip 127.0.0.1] log.py:222 - Forbidden (CSRF cookie not set.): /search/course_discovery/
      lms_stderr_log_parser:
        inputs:
          - lms_stderr_log
        type: remap
        source: |
          match, err = parse_regex(
            .message,
            r'(?ms)^\[(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+\-]\d{4})\] \[(?P<pid>\d+)\] \[(?P<log_level>[A-Z]+)\] (?P<message>.*)'
          )
          if match != null {
            .@timestamp = parse_timestamp!(match.time, "%F %T %z")
          } else {
            match, err = parse_regex(
              .message,
              r'(?ms)^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}) (?P<log_level>\S+) (?P<pid>\d+) \[(?P<namespace>.*?)\] \[user (?P<user>.*?)\] \[ip (?P<client_ip>.*?)\] (?P<file>.*?):(?P<line_number>\d+) - (?P<message>.*)'
            )
            if match != null {
              .@timestamp = parse_timestamp!(match.time, "%F %T,%3f")
            }
          }
          if err == null {
            .time = .@timestamp
            .message = match.message
            .log_level = match.log_level
            .pid = match.pid
            if exists(match.namespace) {
              .namespace = match.namespace
            }
            if exists(match.user) {
              .user = match.user
            }
            if exists(match.client_ip) {
              .client_ip = match.client_ip
            }
            if exists(match.file) {
              .file = match.file
            }
            if exists(match.line_number) {
              .line_number = match.line_number
            }
            .labels = ["edx_cms_stderr"]
            .environment = "{{ environment }}"
          } else {
            log(err, level: "error")
            .malformed = true
          }

      lms_stderr_malformed_message_filter:
        inputs:
          - lms_stderr_log_parser
        type: filter
        condition: .malformed != true

      lms_stderr_sampler:
        inputs:
          - lms_stderr_malformed_message_filter
        type: filter
        condition: "! match!(.message, r'^(GET|POST|HEAD|PUT)')"

      # gitreload log sample:
      # 2021-02-28 19:54:48,495 DEBUG 2894216 [gitreload] web.py:64 - ip-10-7-3-149- Received push event from github
      #
      gitreload_parser:
        inputs:
          - gitreload_log
        type: remap
        source: |
          matches, err = parse_regex(
            .message,
            r'(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}) (?P<log_level>[A-Z]+) (?P<pid>\d+) \[.*?\] (?P<file>.+?):(?P<line_number>\d+) - (?P<host>.+?)- (?P<message>.*)'
          )
          if matches != null {
            .message = matches.message
            .log_level = matches.log_level
            .pid = matches.pid
            .file = matches.file
            .line_number = matches.line_number
            .host = matches.host
            .@timestamp = parse_timestamp!(matches.time, "%F %T,%3f")
            .time = .@timestamp
            .labels = ["edx_gitreload"]
            .environment = "{{ environment }}"
          } else {
            log(err, level: "error")
            .malformed = true
          }

      gitreload_malformed_message_filter:
        inputs:
          - gitreload_parser
        type: filter
        condition: .malformed != true

      xqueue_stderr_log_parser:
        inputs:
          - xqueue_stderr_log
        type: remap
        source: |
          matches, err = parse_regex(
            .message,
            r'(?ms)^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[(?P<pid>.*?)\] \[(?P<log_level>).*?\] (?P<message>.*)'
          )
          if matches != null {
            .message = matches.message
            .pid = matches.pid
            .log_level = matches.log_level
            .@timestamp = parse_timestamp!(matches.time, "%F %T")
            .time = .@timestamp
            .labels = ["edx_xqueue"]
            .environment = "{{ environment }}"
          } else {
            log(err, level: "error")
            .malformed = true
          }

      xqueue_stderr_malformed_message_filter:
        inputs:
          - xqueue_stderr_log_parser
        type: filter
        condition: .malformed != true

      xqueue_stderr_httpreq_filter:
        inputs:
          - xqueue_stderr_malformed_message_filter
        type: filter
        condition: "!match(.message, r'^(GET|POST|HEAD|PUT)')"

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
        type: remap
        source: |
          matches, err = parse_regex(
            .message,
            r'(?ms)^\[(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}): (?P<log_level>[A-Z]+)/(?P<process>.*?)\] (?P<message>.*)'
          )
          if matches != null {
            .message = matches.message
            .log_level = matches.log_level
            .process = matches.process
            .@timestamp = parse_timestamp!(matches.time, "%F %T,%3f")
            .time = .@timestamp
            .labels = ["edx_worker"]
            .environment = "{{ environment }}"
          } else {
            log(err, level: "error")
            .malformed = true
          }

      # edX worker's "lms" supervisor stderr log,
      # e.g. /edx/var/log/supervisor/lms_default_4-stderr.log
      # is formatted as in this example:
      #
      # 2021-02-25 19:45:01,275 WARNING 1403559 [edx_toggles.toggles.internal.waffle] [user None] [ip None] waffle.py:207 - Grades: Flag 'grades.enforce_freeze_grade_after_course_end' accessed without a request
      #
      worker_lms_stderr_log_parser:
        inputs:
          - worker_lms_stderr_log
        type: remap
          matches, err = parse_regex(
            .message,
            r'(?ms)^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}) (?P<log_level>[A-Z]+) (?P<pid>\d+) \[(?P<namespace>.*?)\] \[user (?P<user>.*?)\] \[ip (?P<client_ip>.*?)\] (?P<file>.+?):(?P<line_number>\d+) - (?P<message>.*)'
          )
          if matches != null {
            .message = matches.message
            .log_level = matches.log_level
            .pid = matches.pid
            .namespace = matches.namespace
            .user = matches.user
            .client_ip = matches.client_ip
            .file = matches.file
            .line_number = matches.line_number
            .@timestamp = parse_timestamp!(matches.time, "%F %T,%3f")
            .time = .@timestamp
            .labels = ["edx_worker"]
            .environment = "{{ environment }}"
          } else {
            log(err, level: "error")
            .malformed = true
          }

      worker_stderr_malformed_message_filter:
        inputs:
          - worker_cms_stderr_log_parser
          - worker_lms_stderr_log_parser
        type: filter
        condition: .malformed != true

      {% endif %}

      tracking_log_parser:
        inputs:
          - tracking_log
        type: remap
        source: |
          parsed, err = parse_json(.message)
          if parsed != null {
            del(.message)
            ., err = merge(., parsed)
            .labels = ["edx_tracking"]
            .environment = "{{ environment }}"
          } else {
            log(err, level: "error")
            .malformed = true
          }

      tracking_log_malformed_message_filter:
        inputs:
          - tracking_log_parser
        type: filter
        condition: .malformed != true

      tracking_log_elasticsearch_timestamper:
        inputs:
          - tracking_log_malformed_message_filter
        type: remap
        source: |
          .@timestamp = parse_timestamp!(.time, "%FT%T%.6f%:z")
          .time = .@timestamp

      auth_log_parser:
        inputs:
          - auth_log
        type: remap
        source: |
          matches, err = parse_regex(
            .message,
            r'^(?P<time>\w{3}\s+\d+\s+\d{2}:\d{2}:\d{2}) \S+ (?P<process>.*?): (?P<message>.*)'
          )
          if matches != null {
            .message = matches.message
            .process = matches.process
            .@timestamp = parse_timestamp!(matches.time, "%b %e %Tf")
            .time = .@timestamp
            .labels = ["authlog", "edx_authlog"]
            .environment = "{{ environment }}"
          } else {
            log(err, level: "error")
            .malformed = true
          }

      auth_log_malformed_message_filter:
        inputs:
          - auth_log_parser
        type: filter
        condition: .malformed != true

      auth_log_cron_filter:
        inputs:
          - auth_log_malformed_message_filter
        type: filter
        condition: '! contains!(.process, "CRON")'

    sinks:

      {% if 'edx' in salt.grains.get('roles') %}

      elasticsearch_nginx_access:
        inputs:
          - nginx_access_log_healthcheck_filter
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-mitx-nginx-access-%Y.%W
        healthcheck: false

      elasticsearch_nginx_error:
        inputs:
          - nginx_error_log_malformed_message_filter
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-mitx-nginx-error-%Y.%W
        healthcheck: false

      elasticsearch_gitreload:
        inputs:
          - gitreload_malformed_message_filter
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-mitx-gitreload-%Y.%W
        healthcheck: false

      {% endif %}

      elasticsearch_lms_cms_worker:
        inputs:
          {% if 'edx' in salt.grains.get('roles') %}
          - cms_stderr_httpreq_filter
          - lms_stderr_sampler
          - xqueue_stderr_httpreq_filter
          {% endif %}
          {% if 'edx-worker' in salt.grains.get('roles') %}
          - worker_stderr_malformed_message_filter
          {% endif %}
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-mitx-stderr-%Y.%W
        healthcheck: false

      elasticsearch_tracking:
        inputs:
          - tracking_log_elasticsearch_timestamper
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-mitx-tracking-%Y.%W
        healthcheck: false

      elasticsearch_authlog:
        inputs:
          - auth_log_cron_filter
        type: elasticsearch
        endpoint: 'http://operations-elasticsearch.query.consul:9200'
        index: logs-authlog-%Y.%W

      s3_tracking:
        inputs:
          - tracking_log_malformed_message_filter
        type: aws_s3
        bucket: {{ tracking_bucket }}
        region: us-east-1
        key_prefix: "logs/%F-%H_"
        encoding:
          codec: ndjson
        batch:
          timeout_secs: {{ 60 * 60 }}
          max_bytes: {{ 1024 * 1024 * 1024 * 2 }}
        healthcheck: false
