{% set redash_env = salt.pillar.get('django:environment') %}

create_env_file_for_redash:
  file.managed:
    - name: /opt/{{ salt.pillar.get('django:app_name') }}/.env
    - contents: |
        {%- for var, val in redash_env.items() %}
        {{ var }}={{ val }}
        {%- endfor %}
    - require:
        - archive: deploy_application_source_to_destination
