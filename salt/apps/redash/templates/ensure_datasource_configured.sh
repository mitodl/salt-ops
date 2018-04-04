#!/bin/bash

NAME="{{ ds.name }}"
DS_TYPE={{ ds.type }}

RESULT=$(python manage.py ds edit --type $DS_TYPE --options '{{ ds.options|json }}' "$NAME")
if [ $(echo $RESULT | grep "Couldn't find") ]
then
    python manage.py ds new --type $DS_TYPE --options '{{ ds.options|json }}' "$NAME"
else
    echo "$NAME successfully updated"
fi
