#!/usr/bin/env bash
set -xe
# Create directories and download Kubernetes Components
mkdir -p /etc/kubernetes/descriptors /etc/kubernetes/manifests /etc/kubernetes/ssl /opt/bin
if [[ -x /opt/bin/kubelet ]]; then
    echo "Kubelet already installed"
else
    curl -o /opt/bin/kubelet http://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kubelet
    chmod +x /opt/bin/kubelet
fi
if [[ -x /opt/bin/kubectl ]]; then
    echo "Kubectl already installed"
else
    curl -o /opt/bin/kubectl http://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kubectl
    chmod +x /opt/bin/kubectl
fi
source /etc/pidalio.env
# Launch ETCD
export DOCKER_HOST=unix:///var/run/weave/weave.sock
docker pull cedbossneo/etcd-cluster-on-docker
docker run -e AUTHORITATIVE_ID=${PEER} -e ID=${NODE_IP} -e FS_PATH=/var/etcd --rm --name=etcd -e NODE_COUNT=3 -p 2379:2379 -p 2380:2380 -p 4001:4001 -p 7001:7001 cedbossneo/etcd-cluster-on-docker
