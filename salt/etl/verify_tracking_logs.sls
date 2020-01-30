{% set time = salt.status.time('%Y-%m-%d') %}
{% set buckets = ['odl-residential-tracking-data', 'odl-xpro-edx-tracking-data'] %}

{% for bucket in buckets %}
verify_tracking_logs_in_{{ bucket }}:
  module.run:
    - name: s3.head
    - bucket: {{ bucket }}
    - path: '/logs/{{ time }}-00_0'

send_failure_event:
  salt.runner:
    - name: event.send
    - tag: verify_tracking_logs/failure
    - data:
        bucket: {{ bucket }}
    - onfail:
      - salt: verify_tracking_logs_in_{{ bucket }}
{% endfor %}
