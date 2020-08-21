caddy:
  install_from_repo: True
  enable_api: False
  config:
    logging:
      sink:
        writer:
          output: file
          filename: /var/log/caddy/caddy-sink.log
          roll: True
          roll_size_mb: 10
          roll_gzip: True
      logs:
        default:
          writer:
            output: file
            filename: /var/log/caddy/caddy.log
            roll: True
            roll_size_mb: 10
            roll_gzip: True
          encoder:
            format: json
          level: WARN
    storage:
      module: file_system
      root: /var/lib/caddy/
    apps:
      http:
        http_port: 80
        https_port: 443
