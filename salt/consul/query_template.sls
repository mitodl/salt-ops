create_query_template_for_nearest_service:
  http.query:
    - name: 'http://consul.service.consul:8500/v1/query'
    - method: POST
    - data: >-
        {
            "Name": "nearest",
            "Template": {
              "Type": "name_prefix_match",
              "Regexp": "^nearest-(.*?)$"
            },
            "Service": {
              "Service": "${match(1)}",
              "Near": "_agent"
            }
        }
    - match: (ID|existing)
    - match_type: pcre
    - decode: True
    - raise_error: False
