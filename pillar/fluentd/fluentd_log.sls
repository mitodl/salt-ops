fluentd:
  configs:
    - name: fluentd_log
      settings:
        - directive: label
          directive_arg: '@FLUENT_LOG'
          attrs:
            - nested_directives:
              - directive: filter
                attrs:
                  - '@type': record_transformer
                  - nested_directives:
                    - directive: record
                      attrs:
                        - host: "#{Socket.gethostname}"
