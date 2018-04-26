edx:
  ansible_vars:
    EDXAPP_CELERY_BROKER_HOSTNAME: nearest-rabbitmq.query.consul
    EDXAPP_CELERY_BROKER_TRANSPORT: 'amqp'
    EDXAPP_EXTRA_MIDDLEWARE_CLASSES: [] # Worth keeping track of in case we need to take advantage of it
    EDXAPP_MONGO_REPLICA_SET: rs0
    EDXAPP_MYSQL_CSMH_DB_NAME: edxapp_csmh_{{ purpose_suffix }}
    EDXAPP_MYSQL_CSMH_HOST: {{ MYSQL_HOST }}
    EDXAPP_MYSQL_CSMH_PASSWORD: {{ edxapp_csmh_mysql_creds.data.password }}
    EDXAPP_MYSQL_CSMH_PORT: {{ MYSQL_PORT }}
    EDXAPP_MYSQL_CSMH_USER: {{ edxapp_csmh_mysql_creds.data.username }}
    EDXAPP_PLATFORM_DESCRIPTION: 'MITx Residential Online Course Portal'
    EDXAPP_PRIVATE_REQUIREMENTS:
        # For Harvard courses:
        # Peer instruction XBlock
        - name: ubcpi-xblock==0.6.4
        # Vector Drawing and ActiveTable XBlocks (Davidson)
        - name: git+https://github.com/open-craft/xblock-vectordraw.git@c57df9d98119fd2ca4cb31b9d16c27333cdc65ca#egg=xblock-vectordraw==0.2.1
          extra_args: -e
        - name: git+https://github.com/open-craft/xblock-activetable.git@e933d41bb86a8d50fb878787ca680165a092a6d5#egg=xblock-activetable
          extra_args: -e
       # MITx Residential XBlocks
        - name: git+https://github.com/mitodl/edx-sga@5f21fb4900e1cde573a5406572d3f31a0ea7d5dd#egg=edx-sga==0.8.1
          extra_args: -e
        - name: git+https://github.com/mitodl/rapid-response-xblock@4251bb15124bdf0b681b431fa1cd67fd094387c4#egg=rapid-response-xblock
          extra_args: -e
