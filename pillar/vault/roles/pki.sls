{% set env_settings = salt.cp.get_url("https://raw.githubusercontent.com/mitodl/salt-ops/main/salt/environment_settings.yml", dest=None)|load_yaml %}
{% set ttl = '2880h' %} # FOUR MONTHS
{% set ou = 'Open Learning' %}
{% set org = 'Massachusetts Institute of Technology' %}
{% set country = 'US' %}
{% set locality = 'Cambridge' %}
{% set street_address = '77 Massachusetts Ave' %}
{% set postal_code = '02139' %}
{% set fluentd_aggregators = 'operations-fluentd.query.consul' %}

vault:
  roles:
    {% for env_name, env_data in env_settings.environments.items() %}
    {% for app in env_data.get('backends', {}).get('pki', []) %}
    {% for type in ['client', 'server'] %}
    {{ app }}-{{ env_name }}-{{ type }}-pki:
      backend: pki-intermediate-{{ env_name }}
      name: {{ app }}-{{ type }}
      options:
        {% if type == 'server' %}
        server_flag: true
        allowed_domains: "{{ app }}.service.consul, nearest-{{ app }}.query.consul, {{ fluentd_aggregators }}, {{ app }}-master.service.consul, {{ app }}.service.operations.consul"
        {% else %}
        client_flag: true
        allowed_domains: "{{ app }}.*.{{ env_name }}"
        allow_glob_domains: true
        {% endif %}
        ttl: {{ ttl }}
        max_ttl: {{ ttl }}
        key_type: rsa
        key_bits: 4096
        key_usage: "DigitalSignature, KeyAgreement, KeyEncipherment"
        generate_lease: true
        ou: {{ ou }}
        organization: {{ org }}
        country: {{ country }}
        locality: {{ locality }}
        street_address: {{ street_address }}
        postal_code: {{ postal_code }}
        require_cn: true
    {% endfor %}
    {% endfor %}
    {% endfor %}
