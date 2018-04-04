#!/bin/bash

NAME="{{ ds.name }}"
DS_TYPE={{ ds.type }}

RESULT=$(python manage.py ds edit --type $DS_TYPE --options '{{ ds.options|json }}' "$NAME")
if [ $(echo $RESULT | grep -v "Couldn't find") ]
then
    echo "$NAME successfully updated"
else
    python manage.py ds new --type $DS_TYPE --options '{{ ds.options|json }}' "$NAME"
fi
