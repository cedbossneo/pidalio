#!/usr/bin/env bash
for file in $(ls /opt/pidalio/kube/units/master/*.service)
do
    sed -i s/\\\$region\\\$/${REGION}/g ${file}
done
