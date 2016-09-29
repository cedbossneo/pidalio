#!/usr/bin/env bash
rm -f /etc/kubernetes/descriptors/*
cp -Rf /opt/pidalio/kube/kubelet/descriptors/* /etc/kubernetes/descriptors
for file in $(ls /etc/kubernetes/descriptors/dns/*.yaml)
do
    sed -i s/\\\$domain\\\$/${DOMAIN}/g ${file}
done
