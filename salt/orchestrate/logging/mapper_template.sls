# Obtain the grains for one of the elasticsearch nodes
{% set grains = salt.saltutil.runner(
    'mine.get',
    tgt='roles:elasticsearch', fun='grains.item', tgt_type='grain'
    )[0]['grains'] %}

# PUT the mapper template into the _template index
put_elasticsearch_mapper_template:
  http.query:
    - name: https://{{ grains['external_ip'] }}/_template/logstash
    - data_file: salt://orchestrate/logging/files/mapper_template.json
    - method: PUT
    - status: 200
