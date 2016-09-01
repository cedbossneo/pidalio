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
EXISTING_IPS=$(/opt/bin/weave dns-lookup etcd)
ID="-1"
for ip in $(seq 0 2)
do
    if [[ "$EXISTING_IPS" == *"10.2.2.$ip"* ]]
    then
        echo "Etcd $ip already exist";
    else
        ID="${ip}"
        break;
    fi
done
if [ "$ID" -eq "-1" ]
then
    docker run --rm -p 2379:2379 -p 2380:2380 -p 4001:4001 -p 7001:7001 cedbossneo/etcd-cluster-on-docker /bin/etcd_proxy.sh
else
    docker run -e WEAVE_CIDR=10.2.2.${ID}/8 -e ID=${ID} -e FS_PATH=/var/etcd -v /var/etcd:/opt/etcd  --rm --name=etcd -p 2379:2379 -p 2380:2380 -p 4001:4001 -p 7001:7001 cedbossneo/etcd-cluster-on-docker
fi
