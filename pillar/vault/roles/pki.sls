{% set env_settings = salt.cp.get_file_str("salt://environment_settings.yml")|load_yaml %}
{% set ttl = '8760h' %} # ONE_YEAR
{% set ou = 'Open Learning' %}
{% set org = 'Massachusetts Institute of Technology' %}
{% set country = 'US' %}
{% set locality = 'Cambridge' %}
{% set street_address = '77 Massachusetts Ave' %}
{% set postal_code = '02139' %}

vault:
  roles:
    {% for env in env_settings.environments %}
    {% for app in env.backends.pki %}
    {{ app }}-{{ env }}-pki:
      backend: pki-int-{{ env }}
      {% for type in ['client', 'server'] %}
      name: pki-{{ env }}-{{ app }}-{{ type }}
      {% endfor %}
      ttl: {{ ttl }}
      max_ttl: {{ ttl }}
      allowed_domains:
        - {{ app }}.service.consul
        - nearest-{{ app }}.query.consul
        {% if app == 'mongodb' %}
        - {{ app }}-master.service.consul
        {% endif %}
      {% if type == 'server' %}
      server_flag: true
      {% else %}
      client_flag: true
      {% endif %}
      key_type: rsa
      key_bits: 4096
      key_usage:
        - DigitalSignature
        - KeyAgreement
        - KeyEncipherment
      ou: {{ ou }}
      organization: {{ org }}
      country: {{ country }}
      locality: {{ locality }}
      street_address: {{ street_address }}
      postal_code: {{ postal_code }}
      require_cn: true
    {% endfor %}
    {% endfor %}
