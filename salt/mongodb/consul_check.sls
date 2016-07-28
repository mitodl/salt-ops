create_mongodb_consul_check_script:
  file.managed:
    - name: /consul/scripts/mongo_is_master.sh
    - makedirs: True
    - mode: 0755
    - contents: |
        #!/bin/bash

        ISMASTER=$(/usr/bin/mongo --quiet --eval 'db.isMaster().ismaster')
        if [ "$ISMASTER" = "true" ]
        then
            exit 0
        else
            exit 2
        fi
