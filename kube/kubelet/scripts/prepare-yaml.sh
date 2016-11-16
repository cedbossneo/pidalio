#!/usr/bin/env bash
rm -Rf /etc/kubernetes/descriptors/*
cp -Rf /opt/pidalio/kube/kubelet/descriptors/* /etc/kubernetes/descriptors
for file in $(ls /etc/kubernetes/descriptors/dns/*.yaml /etc/kubernetes/descriptors/ceph/*.yaml)
do
    sed -i s/\\\$domain\\\$/${DOMAIN}/g ${file}
    sed -i s/\\\$node_type\\\$/${NODE_TYPE}/g ${file}
    sed -i s/\\\$CEPH_DISK_DEVICE\\\$/${CEPH_DISK_DEVICE}/g ${file}
done
