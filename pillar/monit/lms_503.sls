{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set purpose = salt.grains.get('purpose', 'current-residential-live') %}
{% set environment = salt.grains.get('environment', 'mitx-qa') %}
{% set purpose_data = env_settings.environments[environment].purposes[purpose] %}

monit_app:
  modules:
    lms_503:
      host:
        custom:
          name: {{ purpose_data.domains.lms }}
        with:
          address: {{ purpose_data.domains.lms }}
        if:
          failed: port 443 protocol https status = 503
          action: exec "/bin/sh -c /usr/local/bin/slack.sh"
