#!/usr/bin/env bash
for file in $(ls /opt/descriptors/*.yaml /opt/manifests/master/*.yaml /opt/manifests/node/*.yaml)
do
    sed -i s/\\\$domain\\\$/${DOMAIN}/g $file
    sed -i s/\\\$private_ipv4\\\$/${NODE_IP}/g $file
done
