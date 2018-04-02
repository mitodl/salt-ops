#!/bin/bash

OPTIONS='{{ ds.options|json }}'
NAME="{{ ds.name }}"
DS_TYPE={{ ds.type }}

RESULT=$(python manage.py ds edit --type $DS_TYPE --options "$OPTIONS" "$NAME")
if [ $(echo $RESULT | grep -v "Couldn't find") ]
then
    echo "$NAME successfully updated"
else
    python manage.py ds new --type $DS_TYPE --options "$OPTIONS" "$NAME"
fi
