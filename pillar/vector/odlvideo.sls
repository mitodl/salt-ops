vector:
  extra_configurations:
  - name: odlvideo_logs
    content:
      log_schema:
        timestamp_key: vector_timestamp
        host_key: log_host
      sources:
        collect_odlvideo_nginx_access_logs:
          type: file
          read_from: end
          file_key: log_file
          include:
          - /var/log/nginx/access.log
        collect_odlvideo_nginx_error_logs:
          type: file
          read_from: end
          file_key: log_file
          include:
          - /var/log/nginx/error.log
        collect_odlvideo_django_logs:
          type: file
          read_from: end
          file_key: log_file
          include:
          - /var/log/odl-video/django.log
        collect_auth_logs:
        {{ salt.pillar.get('vector:base_auth_log_collection')|yaml(False)|indent(8) }}
      transforms:
        parse_odlvideo_nginx_access_logs:
          type: remap
          inputs:
          - 'collect_odlvideo_nginx_access_logs'
          source: |
            parsed, err = parse_regex(.message, r'^time=(?P<time>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2})\sclient=(?P<client>[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\smethod=(?P<method>\S*)\srequest="(?P<request>.*)"\srequest_length=(?P<request_length>\d+)\sstatus=(?P<status>\d+)\sbytes_sent=(?P<bytes_sent>\d+)\sbody_bytes_sent=(?P<body_bytes_sent>\d+)\sreferer=(?P<referer>.*)\suser_agent="(?P<user_agent>.+)"\supstream_addr=(?P<upstream_addr>.+)\supstream_status=(?P<upstream_status>.+)\srequest_time=(?P<request_time>.+)\srequest_id=(?P<request_id>\w+)\supstream_response_time=(?P<upstream_response_time>.+)\supstream_connect_time=(?P<upstream_connect_time>.+)\supstream_header_time=(?P<upstream_header_time>.*)$')
            if err != null {
              .parse_error = err
            }
            err = null

            . = merge(., parsed)
            .log_process = "nginx"
            .log_type = "odl.nginx.access"
            .environment = "${ENVIRONMENT}"
      
            parsed_bs, err = to_int(.bytes_sent)
            if err == null {
              .bytes_sent = parsed_bs
            }
            err = null
            parsed_bbs, err = to_int(.body_bytes_sent)
            if err == null {
              .body_bytes_sent = parsed_bbs
            }
            err = null
            parsed_rl, err = to_int(.request_length)
            if err == null {
              .request_length = parsed_rl
            }
            err = null
            parsed_rt, err = to_float(.request_time)
            if err == null {
              .request_time = parsed_rt
            }
            err = null
            parsed_status, err = to_int(.status)
            if err == null {
              .status = parsed_status
            }
            err = null
            parsed_usct, err = to_float(.upstream_connect_time)
            if err == null {
              .upstream_connect_time = parsed_usct
            }
            err = null
            parsed_usht, err = to_float(.upstream_header_time)
            if err == null {
              .upstream_header_time = parsed_usht
            }
            err = null
            parsed_uprt, err = to_float(.upstream_response_time)
            if err == null {
              .upstream_response_time = parsed_uprt
            }
            err = null
            parsed_ups, err = to_int(.upstream_response)
            if err == null {
              .upstream_status = parsed_ups
            }
            err = null
        filter_healthchecks_odlvideo_nginx_access_logs:
          inputs:
          - 'parse_odlvideo_nginx_access_logs'
          type: filter
          condition: '! contains!(.user_agent, "ELB-HealthChecker")'
        parse_odlvideo_nginx_error_logs:
          type: remap
          inputs:
          - 'collect_odlvideo_nginx_error_logs'
          source: |
            parsed, err = parse_regex(.message, r'^(?P<time>\d{4}/\d{2}/\d{2}\s\d{2}:\d{2}:\d{2})\s\[(?P<severity>.*)\]\s(?P<pid>\d*)#(?P<tid>\d*):\s\*(?P<cid>\d*)\s(?P<message>.*),\sclient:\s(?P<client>.*),\sserver:(?P<server>.*)(?P<additional_content>.*)$')
            . = merge(., parsed)
            if err != null {
              .parse_error = err
            }
            .log_process = "nginx"
            .log_type = "odlvideo.nginx.error"
            .environment = "${ENVIRONMENT}"
        parse_odlvideo_django_logs:
          type: remap
          inputs:
          - 'collect_odlvideo_django_logs'
          source: |
            event, err = parse_json(.message)
            if event != null {
              . = merge!(., event)
              .log_process = "odlvideo"
              .log_type = "odlvideo.application"
              .environment = "${ENVIRONMENT}"
            }
        enrich_odlvideo_django_logs:
          type: aws_ec2_metadata
          inputs:
          - 'parse_odlvideo_django_logs'
          namespace: ec2
        parse_auth_logs:
          {{ salt.pillar.get('vector:base_auth_log_parse_source')|yaml(False)|indent(10) }}
      sinks:
        ship_odlvideo_logs_to_grafana_cloud:
          inputs:
          - 'enrich_odlvideo_django_logs'
          - 'filter_healthchecks_odlvideo_nginx_access_logs'
          - 'parse_odlvideo_nginx_error_logs'
          - 'parse_auth_logs'
          type: loki
          labels:
            environment: ${ENVIRONMENT}
            application: odlvideo
            service: odlvideo
          {{ salt.pillar.get('vector:base_loki_configuration')|yaml(False)|indent(10) }}
