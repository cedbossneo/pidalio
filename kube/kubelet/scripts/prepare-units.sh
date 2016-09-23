#!/usr/bin/env bash
source /etc/pidalio.env
for file in $(ls /opt/pidalio/kube/units/master/*.service)
do
    sed -i s/\\\$token\\\$/${PIDALIO_TOKEN}/g ${file}
done
