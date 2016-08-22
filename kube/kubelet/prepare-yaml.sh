#!/usr/bin/env bash
for file in $(ls /etc/kubernetes/descriptors/*.yaml /etc/kubernetes/manifests/*.yaml)
do
    sed -i s/\$domain\$/${DOMAIN}/g $file
    sed -i s/\$private_ipv4\$/${NODE_IP}/g $file
done
