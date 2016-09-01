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
if [[ -x /opt/bin/etcd2-bootstrapper ]]; then
    echo "Etcd2 Bootstrapper already installed"
else
    wget -O /opt/bin/etcd2-bootstrapper https://github.com/glerchundi/etcd2-bootstrapper/releases/download/v0.3.0/etcd2-bootstrapper-linux-amd64
    chmod +x /opt/bin/etcd2-bootstrapper
fi
source /etc/pidalio.env
# Configure ETCD
if [[ "$PEER" == "$NODE_IP" ]]
then
    MEMBERS="$NODE_FQDN=$NODE_PUBLIC_IP"
else
    until curl -s http://$PEER:2380/members
    do
        echo "Trying to find members"
        sleep 10
    done
    MEMBERS=$(curl -s http://$PEER:2380/members | jq -r '.[] | "\(.name)=\(.peerURLs[0])"')
fi
ETCD_PEERS=""
for MEMBER in ${MEMBERS}
do
  ETCD_PEERS=${MEMBER},${ETCD_PEERS}
done
ETCD_PEERS=$(echo ${ETCD_PEERS}|sed -rn 's/^(.*),$/\1/p' | sed 's/http:\/\///g' | sed 's/:2380//g')

echo "EtcD peers: $ETCD_PEERS"
until /opt/bin/etcd2-bootstrapper --me ${NODE_FQDN}=${NODE_PUBLIC_IP} --members ${ETCD_PEERS} --out /etc/etcd.env
do
    echo "Trying to register Etcd node"
    sleep 10
done
source /etc/etcd.env
/usr/bin/etcd2 \
    -advertise-client-urls=http://${NODE_PUBLIC_IP}:2379 \
    -initial-advertise-peer-urls=http://${NODE_PUBLIC_IP}:2380 \
    -listen-client-urls=http://0.0.0.0:2379 \
    -listen-peer-urls=http://0.0.0.0:2380
