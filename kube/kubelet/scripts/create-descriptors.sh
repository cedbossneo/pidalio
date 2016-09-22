#!/usr/bin/env bash
until curl -m 5 http://localhost:8080/healthz
do
    echo "Waiting for master to be ready"
    sleep 10
done
# Initialize Kubernetes Addons
/opt/bin/kubectl create -f /etc/kubernetes/descriptors
# Initialize Ceph
# /opt/pidalio/kube/kubelet/scripts/ceph/install-ceph.sh
