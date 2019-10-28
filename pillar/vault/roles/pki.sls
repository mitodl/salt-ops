{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ttl = '8760h' %} # ONE_YEAR
{% set ou = 'Open Learning' %}
{% set org = 'Massachusetts Institute of Technology' %}
{% set country = 'US' %}
{% set locality = 'Cambridge' %}
{% set street_address = '77 Massachusetts Ave' %}
{% set postal_code = '02139' %}

{% set key_usage_list = "{'key_usage': '["DigitalSignature", "KeyAgreement", "KeyEncipherment"]'}"|load_json %}

vault:
  roles:
    {% for env_name, env_data in env_settings.environments.items() %}
    {% for app in env_data.get('backends', {}).get('pki', []) %}
    {% set server_allowed_domains = "{'allowed_domains': '["{}.service.consul", "nearest-{}.query.consul", "{}-master.service.consul", "{}.service.operations.consul"]'.format(app)}"|load_json %}
    {% set client_allowed_domains = "{'allowed_domains': '["{}.*.{}"]'.format(app, env_name)}"|load_json %}
    {% for type in ['client', 'server'] %}
    {{ app }}-{{ env_name }}-{{ type }}-pki:
      backend: pki-intermediate-{{ env_name }}
      name: {{ app }}-{{ type }}
      options:
        {% if type == 'server' %}
        server_flag: true
        allowed_domains: {{ server_allowed_domains.allowed_domains }}
        {% else %}
        client_flag: true
        allowed_domains: {{ client_allowed_domains.allowed_domains }}
        allow_glob_domains: true
        {% endif %}
        ttl: {{ ttl }}
        max_ttl: {{ ttl }}
        allow_bare_domains: true
        key_type: rsa
        key_bits: 4096
        key_usage: {{ key_usage_list.key_usage }}
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
