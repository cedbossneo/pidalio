#!/usr/bin/env bash
if [[ "${MASTER}" == "true" ]]
then
  MY_IP=$(ip -4 addr show scope global dev ethwe | grep inet | awk '{print $2}' | cut -d / -f 1)
  curl -s http://pidalio:3000/certs/server\?token\=${PIDALIO_TOKEN}\&ip=${MY_IP} > server.json
  cat server.json | jq -r .privateKey > /etc/kubernetes/ssl/server-key.pem
  cat server.json | jq -r .cert > /etc/kubernetes/ssl/server.pem
fi
exec "$@"
