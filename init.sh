#!/usr/bin/env bash
set -e
source /etc/pidalio.env
/opt/pidalio/kube/kubelet/scripts/download-components.sh
/opt/pidalio/kube/kubelet/scripts/prepare-units.sh
if [[ "${CEPH}" == "True" ]]
then
    /opt/pidalio/kube/kubelet/scripts/ceph/install-ceph-tools.sh
    docker pull ceph/base
fi
docker pull cedbossneo/docker-etcd-rclone
export DOCKER_HOST=unix:///var/run/weave/weave.sock
SLEEP_TIME=$(expr $RANDOM % 50)
echo "Sleeping $SLEEP_TIME seconds"
sleep ${SLEEP_TIME}
EXISTING_ETCD=$(/opt/bin/weave dns-lookup etcd)
echo "Existing ETCD: $EXISTING_ETCD"
if [[ "$EXISTING_ETCD" == "" ]]
then
    docker run -e TOKEN=${PIDALIO_TOKEN} -v /etc/pidalio.etcd.rclone.conf:/root/.rclone.conf --rm --name=etcd -p 2379:2379 -p 2380:2380 cedbossneo/docker-etcd-rclone
else
    echo "Testing $EXISTING_ETCD"
    curl -s -m 1 http://${EXISTING_ETCD}:2379/v2/stats/self
    if [ $? -eq 0 ]
    then
        echo "Etcd $EXISTING_ETCD alive";
    else
        echo "Etcd $EXISTING_ETCD did not come up...exiting"
        exit 1
    fi
    docker run --rm --name=etcd-proxy -p 2379:2379 -p 2380:2380 cedbossneo/docker-etcd-rclone /proxy.sh ${EXISTING_ETCD}
fi
