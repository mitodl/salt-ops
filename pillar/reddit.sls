#!jinja|yaml

{% set ENVIRONMENT = salt.grains.get('environment') %}
{% set app_name = 'reddit' if 'production' in ENVIRONMENT else 'reddit-rc' %}
{% set ELASTICACHE_CONFIG = salt.boto3_elasticache.describe_cache_clusters('{}-memcached'.format(app_name), ShowCacheNodeInfo=True)[0] %}
{% set MEMCACHED_PORT = 11211 %}
{% set CASSANDRA_PORT = 9160 %}
{% set RABBITMQ_HOST = 'nearest-rabbitmq.query.consul' %}
{% set RABBITMQ_PORT = 5672 %}
{% set rabbitmq_creds = salt.vault.read('rabbitmq-{}/creds/reddit'.format(ENVIRONMENT)) %}
{% set postgresql_creds = salt.vault.read('postgresql-{}-reddit/creds/reddit'.format(ENVIRONMENT)) %}
{% set POSTGRESQL_PORT = 5432 %}
{% set POSTGRESQL_HOST = 'postgresql-reddit.service.consul' %}
{% set DISCUSSIONS_HOST = 'discussions-reddit-{}.odl.mit.edu'.format(ENVIRONMENT) %}
{% set admins = 'odldevops' %}
{% set reddit_oauth_client = salt.vault.read('secret-operations/{}/reddit/app-token'.format(ENVIRONMENT)) %}
{% set reddit_admin = salt.vault.read('secret-operations/{}/reddit/admin-user'.format(ENVIRONMENT)) %}
{% set reddit_system_user = salt.vault.read('secret-operations/{}/reddit/system-user'.format(ENVIRONMENT)) %}

{% set cassandra_instances = [] %}
{% for host, addr in salt.saltutil.runner(
    'mine.get',
    tgt='G@roles:cassandra and G@environment:{}'.format(ENVIRONMENT),
    fun='grains.item',
    tgt_type='compound').items() %}
{% do cassandra_instances.append('{0}:{1}'.format(addr['ec2:local_ipv4'], CASSANDRA_PORT)) %}
{% endfor %}

schedule:
  refresh_reddit_configs:
    days: 25
    function: state.sls
    args:
      - reddit.config
      - pgbouncer

reddit:
  environment:
    REDDIT_ERRORS_TO_SENTRY: True
  oauth_client:
    client_id: {{ reddit_oauth_client.data.client_id }}
    client_secret: {{ reddit_oauth_client.data.client_secret }}
  admin_user:
    username: odldevops
    password: {{ reddit_admin.data.password }}
  system_user:
    username: deploy
    password: {{ reddit_system_user.data.password }}
  overrides:
    queue_config_count:
      search_q: 0
      del_account_q: 1
      scraper_q: 1
      markread_q: 2
      commentstree_q: 5
      newcomments_q: 5
      vote_link_q: 5
      vote_comment_q: 5
      automoderator_q: 1
      butler_q: 1
      author_query_q: 2
      subreddit_query_q: 2
      domain_query_q: 2
    mcrouter_config:
      pools:
        default:
          servers:
            {% for host in ELASTICACHE_CONFIG.CacheNodes %}
            - {{ host.Endpoint.Address }}:{{ host.Endpoint.Port }}
            {% endfor %}
  ini_config:
    DEFAULT:
      debug: false
      admins: {{ admins }}
      system_user: deploy
      plugins: refresh_token
      disable_ads: true
      disable_captcha: true
      disable_ratelimit: true
      disable_wiki: true
      disable_require_admin_otp: true

      domain: {{ DISCUSSIONS_HOST }}
      oauth_domain: {{ DISCUSSIONS_HOST }}
      https_endpoint: https://{{ DISCUSSIONS_HOST }}

      activity_endpoint: ''
      tracing_sample_rate: 0

      media_provider: filesystem
      media_fs_root: /var/www/media
      media_fs_base_url_http: https://%(domain)s/media/

      db_table_link: thing, !typeid=3
      db_table_account: thing, !typeid=2
      db_table_message: thing, !typeid=4
      db_table_comment: thing, !typeid=1
      db_table_subreddit: thing, !typeid=5
      db_table_srmember: relation, subreddit, account, !typeid=9
      db_table_friend: relation, account, account, !typeid=10
      db_table_inbox_account_comment: relation, account, comment, !typeid=11
      db_table_inbox_account_message: relation, account, message, !typeid=12
      db_table_moderatorinbox: relation, subreddit, message, !typeid=13
      db_table_report_account_link: relation, account, link, !typeid=14
      db_table_report_account_comment: relation, account, comment, !typeid=15
      db_table_report_account_message: relation, account, message, !typeid=16
      db_table_report_account_subreddit: relation, account, subreddit, !typeid=17
      db_table_award: thing, !typeid=6
      db_table_trophy: relation, account, award, !typeid=18
      db_table_flair: relation, subreddit, account, !typeid=19
      db_table_promocampaign: thing, !typeid=8

      db_servers_link: main, main
      db_servers_account: main
      db_servers_message: main
      db_servers_comment: main
      db_servers_subreddit: main
      db_servers_srmember: main
      db_servers_friend: main
      db_servers_inbox_account_comment: main
      db_servers_inbox_account_message: main
      db_servers_moderatorinbox: main
      db_servers_report_account_link: main
      db_servers_report_account_comment: main
      db_servers_report_account_message: main
      db_servers_report_account_subreddit: main
      db_servers_award: main
      db_servers_trophy: main
      db_servers_flair: main
      db_servers_promocampaign: main

      db_user: {{ postgresql_creds.data.username }}
      db_pass: {{ postgresql_creds.data.password }}
      db_port: {{ 6432 }}
      db_pool_size: 20
      db_pool_overflow_size: 5
      databases: 'main, comment, email, authorize, award, hc, traffic'

      main_db: 'reddit,   127.0.0.1, *,    *,    *,    *,    *'
      comment_db: 'reddit,   127.0.0.1, *,    *,    *,    *,    *'
      comment2_db: 'reddit,   127.0.0.1, *,    *,    *,    *,    *'
      email_db: 'reddit,   127.0.0.1, *,    *,    *,    *,    *'
      authorize_db: 'reddit,   127.0.0.1, *,    *,    *,    *,    *'
      award_db: 'reddit,   127.0.0.1, *,    *,    *,    *,    *'
      hc_db: 'reddit,   127.0.0.1, *,    *,    *,    *,    *'
      traffic_db: 'reddit,   127.0.0.1, *,    *,    *,    *,    *'

      num_mc_clients: 25
      lockcaches: '127.0.0.1:5050'
      permacache_memcaches: '127.0.0.1:5050'
      stalecaches: ''
      hardcache_memcaches: '127.0.0.1:5050'
      mcrouter_addr: '127.0.0.1:5050'

      cassandra_seeds: {{ cassandra_instances|join(',') }}
      cassandra_pool_size: 60
      cassandra_rcl: QUORUM
      cassandra_wcl: QUORUM
      cassandra_default_pool: main

      amqp_host: '{{ RABBITMQ_HOST }}:{{ RABBITMQ_PORT }}'
      amqp_user: '{{ rabbitmq_creds.data.username }}'
      amqp_pass: '{{ rabbitmq_creds.data.password }}'
      amqp_virtual_host: /reddit

      smtp_server: ''
      share_reply: ''
      feedback_email: ''
      notification_email: ''
      ads_email: ''

      sentry_dsn: {{ salt.vault.read('secret-operations/global/reddit/sentry-dsn').data.value }}
      pool_name: {{ ENVIRONMENT }}

      zookeeper_connection: ''

    server:main:
      port: 8001

    secrets:
      generate_refresh_token_client_id: {{ reddit_oauth_client.data.client_id|base64_encode }}

    live_config:
      employees: 'odldevops:admin'
      lumendatabase_org_api_base_url: ''
      feature_https_redirect: 'on'
      feature_force_https: 'on'
      feature_upgrade_cookies: 'on'

    formatter_reddit:
      format: '%(asctime)s - %(filename)s:%(lineno)d -- %(funcName)s [%(levelname)s]: %(message)s'

    logger_root:
      formatter: reddit
      qualname: NOTSET
      handlers: 'logfile, console'

    handlers:
      keys: 'logfile, console'

    handler_logfile:
      class: logging.handlers.RotatingFileHandler
      formatter: reddit
      args: '("/var/log/reddit/reddit.log", "w", 13107200, 10)'

    handler_console:
      class: StreamHandler
      args: '(sys.stdout,)'
      formatter: reddit

  websockets_config:
    'app:main':
      factory: 'reddit_service_websockets.app:make_app'
      amqp.endpoint: nearest-rabbitmq.query.consul:5672
      amqp.vhost: /reddit
      amqp.username: {{ rabbitmq_creds.data.username }}
      amqp.password: {{ rabbitmq_creds.data.password }}
      amqp.exchange.broadcast: sutro
      amqp.exchange.status: reddit_exchange
      amqp.send_status_messages: 'false'
      web.ping_interval: 45
      web.admin_auth: aHVudGVyMg==
      web.conn_shed_rate: 5
      metrics.namespace: websockets
      secrets.path: example_secrets.json
      sentry.dsn: {{ salt.vault.read('secret-operations/global/reddit/sentry-dsn').data.value }}
      sentry.environment: {{ ENVIRONMENT }}

    'server:main':
      factory: baseplate.server.wsgi
      handler: reddit_service_websockets.socketserver:WebSocketHandler

cassandra:
  cluster: nearest-cassandra.query.consul

pgbouncer:
  overrides:
    config:
      databases:
        reddit: >-
          host={{ POSTGRESQL_HOST }}
          dbname=reddit
          user={{ postgresql_creds.data.username }}
          password={{ postgresql_creds.data.password }}
      pgbouncer:
        pool_mode: transaction
        max_client_conn: 300
        default_pool_size: 50
        min_pool_size: 20
        server_tls_sslmode: require
        server_tls_protocols: tlsv1.2
        auth_type: any
