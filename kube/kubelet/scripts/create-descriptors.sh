#!/usr/bin/env bash
i=0
until curl -m 5 http://localhost:8080/healthz && [[ $i != 5 ]]
do
    echo "Waiting for master to be ready"
    sleep 10
    i=$(expr $i + 1)
done
if [[ $i == 5 ]]; then exit 1; fi
# Initialize Kubernetes Addons
/opt/bin/kubectl create -f /etc/kubernetes/descriptors
# Initialize Ceph
# /opt/pidalio/kube/kubelet/scripts/ceph/install-ceph.sh
