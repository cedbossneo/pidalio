#!/usr/bin/env bash
if [[ "$MODE" -eq "master" ]]
then
    curl -s $PIDALIO_URL/certs/admin\?token\=$PIDALIO_TOKEN > admin.json
    cat admin.json | jq -r .cert > /etc/kubernetes/ssl/
fi