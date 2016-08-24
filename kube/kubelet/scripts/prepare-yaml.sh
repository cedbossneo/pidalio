#!/usr/bin/env bash
if [[ "${MASTER}" == "true" ]]
then
  cp /opt/kube/manifests/master/* /etc/kubernetes/manifests
else
  cp /opt/kube/manifests/node/* /etc/kubernetes/manifests
fi
cp /opt/kube/descriptors/* /etc/kubernetes/descriptors
for file in $(ls /etc/kubernetes/descriptors/*.yaml /etc/kubernetes/manifests/*.yaml)
do
    sed -i s/\\\$domain\\\$/${DOMAIN}/g $file
    sed -i s/\\\$private_ipv4\\\$/${NODE_IP}/g $file
done
