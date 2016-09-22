#!/usr/bin/env bash
set -e
# Create directories and download Kubernetes Components
mkdir -p /etc/kubernetes/descriptors /etc/kubernetes/manifests /etc/kubernetes/ssl /opt/bin
if [[ -x /opt/bin/kubelet ]]; then
    echo "Kubelet already installed"
else
    curl -o /opt/bin/kubelet http://storage.googleapis.com/kubernetes-release/release/v1.3.7/bin/linux/amd64/kubelet
    chmod +x /opt/bin/kubelet
fi
if [[ -x /opt/bin/kubectl ]]; then
    echo "Kubectl already installed"
else
    curl -o /opt/bin/kubectl http://storage.googleapis.com/kubernetes-release/release/v1.3.7/bin/linux/amd64/kubectl
    chmod +x /opt/bin/kubectl
fi
/opt/pidalio/kube/kubelet/scripts/prepare-units.sh
#/opt/pidalio/kube/kubelet/scripts/ceph/install-ceph-tools.sh
docker pull cedbossneo/etcd-cluster-on-docker
export DOCKER_HOST=unix:///var/run/weave/weave.sock
source /etc/pidalio.env
SLEEP_TIME=$(expr $RANDOM % 30)
echo "Sleeping $SLEEP_TIME seconds"
sleep ${SLEEP_TIME}
EXISTING_IPS=$(/opt/bin/weave dns-lookup etcd | sort)
EXISTING_IDS=""
for ip in ${EXISTING_IPS}
do
    ETCD_UP=0
    for f in {1..10}; do
        sleep 1
        if curl -s -m 1 http://${ip}:2379/v2/stats/self
        then
            ETCD_UP=1
            break
        fi
    done
    if [ "$ETCD_UP" -eq 0 ]; then
        echo "Etcd $ip did not come up...ignoring"
        continue
    fi
    IP_ID=$(curl -s -m 10 http://${ip}:2379/v2/stats/self | jq -r .name | cut -d'-' -f 2)
    EXISTING_IDS=${IP_ID},${EXISTING_IDS}
    echo "Etcd $ip already exist, ID: $IP_ID";
done
ID="-1"
MAX=$(expr ${ETCD_NODES} - 1)
for id in $(seq 0 ${MAX})
do
    if [[ "$EXISTING_IDS" == *"$id"* ]]
    then
        echo "ID $id already taken";
    else
        ID="${id}"
        break;
    fi
done
if [ "$ID" -eq "-1" ]
then
    echo "Running as proxy"
    docker run --rm --name=etcd-proxy -p 2379:2379 -p 2380:2380 cedbossneo/etcd-cluster-on-docker /bin/etcd_proxy.sh
else
    echo "Using ID: $ID"
    docker run -e ID=${ID} -e FS_PATH=/var/etcd --rm --name=etcd -p 2379:2379 -p 2380:2380 cedbossneo/etcd-cluster-on-docker
fi
