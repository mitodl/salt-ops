base:
  '* and not proxy-*':
    - match: compound
    - common
    - environment_settings
    - vector
  'roles:master':
    - match: grain
    - master
    - master.config
    - vault.roles.apps
    - vault.roles.aws
    - vault.roles.bootcamps
    - vault.roles.micromasters
  master-operations-production:
    - master.production_schedule
  master-operations-qa:
    - master.qa_schedule
  starcellbio*:
    - apps.starcellbio
    - nginx
    - nginx.starcellbio
    - consul
  odl-video-service*:
    - apps.odlvideo
    - nginx
    - nginx.odlvideo
    - consul
    - shibboleth
    - shibboleth.odlvideo
    - logrotate.odlvideo
    - vector.odlvideo
  'proxy-bootcamps-*':
    - match: glob
    - heroku.bootcamps
  'proxy-micromasters-*':
    - match: glob
    - heroku.micromasters
  'proxy-mitxpro-*':
    - match: glob
    - heroku.xpro
  'proxy-mit-open-discussions-*':
    - match: glob
    - heroku.discussions
  'proxy-mitxonline-*':
    - match: glob
    - heroku.mitxonline
  'proxy-ocw-studio-*':
    - match: glob
    - heroku.ocw-studio
  'roles:mitx-cas':
    - match: grain
    - apps.mitx_cas
    - nginx
    - nginx.mitx_cas
    - consul
    - shibboleth
    - shibboleth.mitx_cas
    - vector.cas
  'roles:cassandra':
    - match: grain
    - cassandra
    - consul.cassandra
  'roles:reddit':
    - match: grain
    - nginx
    - nginx.reddit
    - vector.reddit
    - reddit
  'P@environment:(mitx-qa|mitx-production|operations|operations-qa|rc-apps|production-apps)':
    - match: compound
    - consul
  'P@environment:.*apps.*':
    - match: compound
    - consul.apps
  'P@environment:(operations|data)(-qa|-production)?':
    - match: compound
    - consul.operations
  'environment:operations':
    - match: grain
    - consul.operations
  'P@environment:(rc|production)-apps':
    - match: compound
    - rabbitmq.apps
    - consul.apps
  'roles:xqwatcher':
    - match: grain
    - edx.xqwatcher
    - vector.xqwatcher
  'lightsail-xqwatcher-686':
    - match: glob
    - edx.xqwatcher
    - edx.xqwatcher_686
  'xqwatcher-600x*':
    - match: glob
    - edx.xqwatcher_600
  'xqwatcher-686*':
    - match: glob
    - edx.xqwatcher_686_residential
  'xqwatcher-6S082*':
    - match: glob
    - edx.xqwatcher_6S082
  'xqwatcher-940*':
    - match: glob
    - edx.xqwatcher_940
  'roles:rabbitmq':
    - match: grain
    - rabbitmq
    - consul.rabbitmq
    - vector.rabbitmq
  'roles:ocw-cms':
    - match: grain
    - logrotate.ocw_cms
    - apps.ocw
  'roles:ocw-mirror':
    - match: grain
    - apps.ocw
    - logrotate.ocw_mirror
  'G@roles:ocw-mirror and G@ocw-environment:production':
    - match: compound
    - nginx
    - nginx.ocw_mirror
  'roles:ocw-origin':
    - match: grain
    - apps.ocw
    - letsencrypt.ocw_origin
    - nginx
    - nginx.ocw_origin
  'P@roles:ocw-(cms|mirror|origin) and G@ocw-environment:production':
    - match: compound
    - apps.ocw-production
  'P@roles:ocw-(cms|mirror|origin) and G@ocw-environment:qa':
    - match: compound
    - apps.ocw-qa
  'roles:ocw-db':
    - match: grain
    - logrotate.ocw_cms
  'G@roles:ocw-build and G@environment:production-apps':
    - match: compound
    - apps.ocw-next-production
    - caddy
    - caddy.ocw_build
  'G@roles:ocw-build and G@environment:rc-apps':
    - match: compound
    - apps.ocw-next-qa
    - caddy
    - caddy.ocw_build
  'roles:ocw-build':
    - match: grain
    - logrotate.ocw_build
    - vector.ocw_build
